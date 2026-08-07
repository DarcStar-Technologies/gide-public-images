#!/usr/bin/env bash
# Headless-server `session_start` smoke for gide-isabelle-base.
#
# Runs INSIDE the image (the ENTRYPOINT is `isabelle`, so invoke it as
# `docker run -i --entrypoint bash <image> -s -- <args> < this-file`).
#
# WHY THIS EXISTS (gpi#54). The toolchain smoke in
# `build-isabelle-base-image.yml` drives batch `isabelle build`, which
# resolves and caches session dependencies differently from the headless
# server. #54 was a wedge that appeared ONLY on the `isabelle server` +
# `session_start` path — the path a persistent Isabelle daemon drives — so
# a green batch build proved nothing about it. This exercises that path.
#
# It is still a TOOLCHAIN check: it starts a server, loads a pre-baked heap,
# and asserts the session reaches a terminal state. No proof content.
#
# Instrumentation. The discriminating measurement is `t_poly`: the ML
# (PolyML) process is spawned only AFTER `Sessions.deps` finishes resolving
# the theory-source graph, so time-to-poly IS the dependency-resolution cost
# that #54 was traced to. "No ML process, server idle, no terminal reply" is
# the issue's exact hang signature, and it is what distinguishes a real wedge
# from a merely slow runner.
#
# Usage: isabelle-daemon-smoke.sh [mode] [session] [ceiling] [nopoly-cutoff]
#   mode          raw   — session_start against the shipped store (default)
#                 probe — first bake the CBO+ODE bridge session from #54's
#                         repro (`session Probe = CBO + sessions ODE`) and put
#                         it in the server's default scope, then session_start.
#                         Diagnostic only; not used by the promotion gate.
#   ceiling       seconds before giving up on a terminal reply (default 900)
#   nopoly-cutoff seconds without any ML process before calling it a hang
#                 (default 480)
#
# The ceiling and cutoff are deliberately generous: on a COLD page cache
# (a freshly pulled image, i.e. every CI run) the first read of the ~2 GB
# CBO heap dominates — a measured cold `session_start` took 222 s where the
# warm repeat took 28 s on the same host. These are wedge detectors, not
# latency SLOs; use the emitted timings for drift, not the thresholds.
#
# Exit: 0 = FINISHED and no source-registration errors; non-zero otherwise.
set -uo pipefail

MODE="${1:-raw}"
SESSION="${2:-Complex_Bounded_Operators}"
CEILING="${3:-900}"
NOPOLY="${4:-480}"
IV="${ISABELLE_VERSION:-Isabelle2025-2}"

now() { date +%s.%N; }
el() { awk -v a="$1" -v b="$2" 'BEGIN{printf "%.1f", b-a}'; }
past() { awk -v d="$1" -v n="$(now)" 'BEGIN{exit !(n>d)}'; }

echo "INFO isabelle_version=${IV}"
echo "INFO afp_registration=$(if [ -f "$HOME/.isabelle/$IV/etc/components" ]; then echo component; else echo roots; fi)"
heaps=""
for h in "$HOME/.isabelle/$IV/heaps/"*/*; do
  [ -e "$h" ] || continue
  b="${h##*/}"
  [ "$b" = log ] && continue
  heaps="${heaps}${b},"
done
echo "INFO heaps=${heaps}"

if [ "$MODE" = probe ]; then
  mkdir -p "$HOME/probe"
  cat > "$HOME/probe/ROOT" <<'EOF'
session Probe = "Complex_Bounded_Operators" +
  sessions
    "Ordinary_Differential_Equations"
EOF
  pb0=$(now)
  if ! isabelle build -d "$HOME/probe" -b Probe > /tmp/probe-build.log 2>&1; then
    echo "RESULT mode=$MODE status=probe_build_failed"
    tail -25 /tmp/probe-build.log
    exit 9
  fi
  echo "INFO probe_build_secs=$(el "$pb0" "$(now)")"
  mkdir -p "$HOME/.isabelle/$IV"
  echo "$HOME/probe" >> "$HOME/.isabelle/$IV/ROOTS"
fi

# --- start the server; time the info banner --------------------------------
# `isabelle server` blocks in the foreground, so background it and poll for
# the banner. A wedge here (banner never printed) is itself a #54 symptom.
rm -f /tmp/server-info.txt
b0=$(now)
isabelle server -n smoke > /tmp/server-info.txt 2>&1 &
bdl=$(awk -v a="$b0" -v t="$CEILING" 'BEGIN{print a+t}')
until grep -q 'password' /tmp/server-info.txt 2>/dev/null; do
  past "$bdl" && break
  sleep 0.25
done
T_BANNER=$(el "$b0" "$(now)")

if ! grep -q 'password' /tmp/server-info.txt 2>/dev/null; then
  echo "RESULT mode=$MODE session=$SESSION status=banner_timeout t_banner=>${CEILING} t_poly=n/a t_total=n/a"
  cat /tmp/server-info.txt
  exit 1
fi

PORT=$(sed -n 's/.*127\.0\.0\.1:\([0-9]*\).*/\1/p' /tmp/server-info.txt)
PASS=$(sed -n 's/.*password "\([^"]*\)".*/\1/p' /tmp/server-info.txt)

# The server protocol is line-based over a plain socket; drive it with bash
# /dev/tcp. (`isabelle client` needs a TTY for jline and silently eats piped
# input, so it cannot be scripted here.)
if ! exec 3<>"/dev/tcp/127.0.0.1/$PORT"; then
  echo "RESULT mode=$MODE session=$SESSION status=connect_failed t_banner=$T_BANNER t_poly=n/a t_total=n/a"
  exit 2
fi
printf '%s\n' "$PASS" >&3
IFS= read -r -t 60 hello <&3
echo "INFO hello=${hello:-<none>}"

# --- session_start, watching for the ML process ----------------------------
: > /tmp/proto.log
rm -f /tmp/poly_first
s0=$(now)
(
  # The ML process's `comm` is not "poly"; only a cmdline match finds it.
  while :; do
    if pgrep -f 'polyml-.*/poly' >/dev/null 2>&1; then now > /tmp/poly_first; exit 0; fi
    sleep 0.25
  done
) &
WATCH=$!

printf 'session_start {"session": "%s"}\n' "$SESSION" >&3
deadline=$(awk -v a="$s0" -v t="$CEILING" 'BEGIN{print a+t}')
nopoly_cut=$(awk -v a="$s0" -v t="$NOPOLY" 'BEGIN{print a+t}')
status=unknown
while :; do
  # Bounded read so the hang checks below still run on a silent socket.
  rem=$(awk -v d="$deadline" -v n="$(now)" 'BEGIN{r=d-n; if (r<1) r=1; if (r>5) r=5; printf "%d", r}')
  if IFS= read -r -t "$rem" line <&3; then
    printf '%.400s\n' "$line" >> /tmp/proto.log
    case "$line" in
      FINISHED*) status=finished; break ;;
      FAILED*)   status=failed;   break ;;
      ERROR*)    status=error;    break ;;
    esac
  fi
  if [ ! -f /tmp/poly_first ] && past "$nopoly_cut"; then status=hang; break; fi
  past "$deadline" && { [ -f /tmp/poly_first ] && status=slow || status=hang; break; }
done
T_TOTAL=$(el "$s0" "$(now)")
kill "$WATCH" 2>/dev/null

T_POLY=n/a
[ -f /tmp/poly_first ] && T_POLY=$(el "$s0" "$(cat /tmp/poly_first)")

MISSING=$(grep -c 'Missing session sources entry' /tmp/proto.log)
CONSUMER=$(grep -c 'Consumer thread failure' /tmp/proto.log)

echo "RESULT mode=$MODE session=$SESSION status=$status t_banner=$T_BANNER t_poly=$T_POLY t_total=$T_TOTAL"
echo "INFO msg_count=$(wc -l < /tmp/proto.log)"
echo "INFO missing_sources=$MISSING"
echo "INFO consumer_failures=$CONSUMER"

# On a wedge, capture WHERE the server is: the #54 signature is the server
# task RUNNABLE inside Sessions.deps/require_thy with no ML process yet.
if [ "$status" = hang ] || [ "$status" = slow ]; then
  JSTACK=""
  for j in /opt/isabelle/contrib/jdk*/*/bin/jstack; do
    [ -x "$j" ] && { JSTACK="$j"; break; }
  done
  JPID=$(pgrep -f 'java .*isabelle.*server' | head -1)
  [ -z "$JPID" ] && JPID=$(pgrep -f 'jdk-.*java' | head -1)
  if [ -n "$JSTACK" ] && [ -n "$JPID" ]; then
    "$JSTACK" -l "$JPID" > /tmp/jstack.txt 2>&1
    echo "--- isabelle threads (name :: state) ---"
    awk '/^"Isabelle/{n=$0; getline s; print n" :: "s}' /tmp/jstack.txt
    echo "--- resolution frames ---"
    grep -m8 -E 'isabelle\.(Sessions|Build|Store|Headless|Resources|Database)' /tmp/jstack.txt \
      || echo "  (none — task never dispatched)"
  fi
fi

echo "--- last protocol lines ---"
tail -3 /tmp/proto.log
isabelle server -n smoke -x >/dev/null 2>&1 || true

# `Missing session sources entry` means AFP source paths are registered under
# a different spelling than the build recorded (gpi#68) — on the server path
# it arrives paired with `Consumer thread failure: "Isabelle.Session.manager"`.
# Fail on it even when the session otherwise reaches FINISHED.
if [ "$status" != finished ]; then
  echo "::error::Headless session_start did not reach FINISHED (status=$status)."
  exit 3
fi
if [ "$MISSING" -gt 0 ] || [ "$CONSUMER" -gt 0 ]; then
  echo "::error::Session source registration errors on the server path (missing=$MISSING consumer=$CONSUMER)."
  exit 4
fi
echo "Headless session_start smoke passed: ${SESSION} reached FINISHED in ${T_TOTAL}s (deps resolved at ${T_POLY}s)."
