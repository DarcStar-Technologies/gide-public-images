#!/usr/bin/env bash
# Append a changelog entry for each published-image Dockerfile a Renovate PR
# changed, so the required `Require changelog entry for image changes` gate
# passes and the curated changelogs/<image>.md stays current. Option A of #43.
#
# Captures the upstream context: a deterministic release-notes link per image,
# plus the actual release notes Renovate already fetched into the PR body
# (embedded, collapsed + capped), so the curated file holds the upstream notes
# rather than just pointing at the PR.
#
# Idempotent: each entry carries a `<!-- renovate-pr-<N> -->` marker, so a
# re-run on the same PR (synchronize) does not duplicate it.
#
# Usage: renovate-changelog.sh <base_ref> <pr_number> <repo> <date> [pr_body_file]
#   base_ref     : ref to diff against and read prior versions from (e.g. origin/main)
#   pr_number    : PR number (idempotency marker + link)
#   repo         : owner/repo, for links
#   date         : YYYY-MM-DD (passed in for determinism/testability)
#   pr_body_file : file with the Renovate PR body (optional; source of release notes)
# Emits `changed=1` (to GITHUB_OUTPUT if set, else stdout) when it modified a file.
set -euo pipefail

BASE_REF="${1:?base_ref}"; PR="${2:?pr_number}"; REPO="${3:?repo}"; DATE="${4:?date}"
BODY_FILE="${5:-}"

declare -A MAP=(
  [tools/lean4-base.Dockerfile]=changelogs/gide-lean4-base.md
  [tools/isabelle-base.Dockerfile]=changelogs/gide-isabelle-base.md
  [tools/z3.Dockerfile]=changelogs/gide-z3.md
  [tools/cvc5.Dockerfile]=changelogs/gide-cvc5.md
  [tools/yices2.Dockerfile]=changelogs/gide-yices2.md
  [tools/dreal.Dockerfile]=changelogs/gide-dreal.md
  [tools/apalache.Dockerfile]=changelogs/gide-apalache.md
)

# Resolve the headline upstream version from a Dockerfile passed on stdin.
resolve_version() {  # $1 = dockerfile path (selects the rule)
  local df="$1" content; content="$(cat)"
  case "$df" in
    tools/lean4-base.Dockerfile)
      printf '%s\n' "$content" | grep -m1 '^ARG MATHLIB_REV=' | sed 's/^ARG MATHLIB_REV=//' ;;
    tools/isabelle-base.Dockerfile)
      local iv at
      iv="$(printf '%s\n' "$content" | grep -m1 '^ARG ISABELLE_VERSION=' | sed 's/^ARG ISABELLE_VERSION=//')"
      at="$(printf '%s\n' "$content" | grep -m1 '^ARG AFP_DATED_TAG=' | sed 's/^ARG AFP_DATED_TAG=//')"
      [ -n "$iv$at" ] && printf '%s-%s' "$iv" "$at" ;;
    *)
      printf '%s\n' "$content" | grep -m1 -oE '^ARG [A-Z0-9_]+_VERSION=[^ ]+' | sed 's/.*=//' ;;
  esac
}

# Deterministic upstream release-notes link for a version bump. Prints
# "Name|URL", or nothing for images with no GitHub release page (isabelle/base
# digests). Mirrors the datasources in renovate.json.
upstream_link() {  # $1 = dockerfile, $2 = version
  local df="$1" v="$2"
  case "$df" in
    tools/z3.Dockerfile)         printf 'Z3|https://github.com/Z3Prover/z3/releases/tag/z3-%s' "$v" ;;
    tools/cvc5.Dockerfile)       printf 'cvc5|https://github.com/cvc5/cvc5/releases/tag/cvc5-%s' "$v" ;;
    tools/yices2.Dockerfile)     printf 'Yices 2|https://github.com/SRI-CSL/yices2/releases/tag/Yices-%s' "$v" ;;
    tools/dreal.Dockerfile)      printf 'dReal|https://github.com/dreal/dreal4/releases/tag/%s' "$v" ;;
    tools/apalache.Dockerfile)   printf 'Apalache|https://github.com/apalache-mc/apalache/releases/tag/v%s' "$v" ;;
    tools/lean4-base.Dockerfile) printf 'Mathlib4|https://github.com/leanprover-community/mathlib4/releases/tag/%s' "$v" ;;
    *) : ;;
  esac
}

# Extract the upstream release notes from the Renovate PR body (the `Release
# Notes` section, between that heading and the `Configuration` heading), strip
# Renovate's own <details>/<summary> wrappers and leading blanks, and cap length.
extract_notes() {  # reads body on stdin
  awk '/^#+[[:space:]]*Release Notes/{f=1;next} /^#+[[:space:]]*Configuration/{f=0} f' \
    | sed -E '/^[[:space:]]*<\/?details>[[:space:]]*$/d; /^[[:space:]]*<summary>.*<\/summary>[[:space:]]*$/d; /^---[[:space:]]*$/d' \
    | sed '/./,$!d' \
    | head -80 \
    | awk 'NF{last=NR} {ln[NR]=$0} END{for(i=1;i<=last;i++) print ln[i]}'
}

mapfile -t files < <(git diff --name-only "${BASE_REF}...HEAD")
changed=0

for df in "${!MAP[@]}"; do
  printf '%s\n' "${files[@]}" | grep -qxF -- "$df" || continue
  cl="${MAP[$df]}"
  marker="<!-- renovate-pr-${PR} -->"
  if grep -qF -- "$marker" "$cl" 2>/dev/null; then
    echo "  ${cl}: already has marker for #${PR}; skipping"
    continue
  fi

  new_ver="$(resolve_version "$df" < "$df" || true)"
  old_ver="$(git show "${BASE_REF}:${df}" 2>/dev/null | resolve_version "$df" 2>/dev/null || true)"

  is_bump=0
  if [ -n "$new_ver" ] && [ "$new_ver" != "$old_ver" ]; then
    is_bump=1; ver="$new_ver"
    body="Bumped to \`${new_ver}\`${old_ver:+ (from \`${old_ver}\`)} via Renovate (#${PR})."
  else
    ver="${new_ver:-${old_ver:-unreleased}}"
    body="Base image / digest refresh via Renovate (#${PR}) — no upstream version change. See PR #${PR}."
  fi

  ef="$(mktemp)"
  rel_tag="$(basename "$cl" .md)-${ver}"
  {
    echo "${marker}"
    echo "## [${ver}] — ${DATE}"
    echo "**Digest:** _published on merge — see GitHub Release \`${rel_tag}\`._"
    echo ""
    # Upstream section: link + captured release notes (version bumps only).
    if [ "$is_bump" = 1 ]; then
      link="$(upstream_link "$df" "$ver")"
      if [ -n "$link" ]; then
        echo "### Upstream"
        echo "- ${link%%|*} \`${ver}\` — [release notes](${link#*|})"
        if [ -n "$BODY_FILE" ] && [ -f "$BODY_FILE" ]; then
          notes="$(extract_notes < "$BODY_FILE" || true)"
          if [ -n "$notes" ]; then
            echo ""
            echo "<details><summary>Upstream release notes (captured from PR #${PR})</summary>"
            echo ""
            printf '%s\n' "$notes"
            echo ""
            echo "</details>"
          fi
        fi
        echo ""
      fi
    fi
    echo "### Composition (this repo)"
    echo "- ${body}"
    echo ""
  } > "$ef"

  if grep -qm1 '^## \[' "$cl"; then
    awk 'NR==FNR{e=e $0 ORS; next} !done && /^## \[/{printf "%s\n", e; done=1} {print}' \
      "$ef" "$cl" > "${cl}.tmp" && mv "${cl}.tmp" "$cl"
  else
    { printf '\n'; cat "$ef"; } >> "$cl"
  fi
  echo "  ${cl}: appended entry for ${ver}"
  changed=1
done

if [ -n "${GITHUB_OUTPUT:-}" ]; then echo "changed=${changed}" >> "$GITHUB_OUTPUT"; fi
echo "changed=${changed}"
