# Isabelle BASE image: Ubuntu + Isabelle distribution + AFP source +
# pre-baked Complex_Bounded_Operators and Ordinary_Differential_Equations
# heap chains.
#
# This is the slow, upstream-driven layer (CBO heap is 90-150 min cold).
# The expensive bake lives in the `heap-builder` stage on its own pinned
# Ubuntu base; the shipped image is a THIN final stage that COPYs the
# baked Isabelle install + heaps onto a separately-pinned, CVE-patched
# Ubuntu runtime base. So a weekly Ubuntu CVE bump (runtime base only)
# rebuilds just the thin final stage and cache-hits the heap — it does
# NOT re-run the 90-150 min bake. The bake re-runs only when
# `ISABELLE_VERSION` / `AFP_*` bump, the heap-builder base is bumped, or
# the bake recipe changes. Registry buildcache `mode=max` persists all
# stages, so the heap-builder stage is restored from cache across
# runtime-only changes.
#
# The theorem-augmented overlay (`tools/isabelle.Dockerfile`) bakes the
# `proofs/Layer1..Layer5` source tree + the GIDE per-layer session heap
# chain on top of this base. Splitting the two layers means an edit to
# `proofs/Layer*/**` or `proofs/Shared/**` only rebuilds the overlay
# (which is much smaller than the full CBO chain), instead of the full
# 90-150 min CBO bake.
#
# Source tarballs come from the GIDE-owned GHCR mirror (#1473 Phase B,
# #1544), NOT directly from `isabelle.in.tum.de` / `isa-afp.org`. The
# upstream is reachable from GitHub-hosted runners but the Blacksmith
# pool that runs the GIDE workflows hits persistent connect timeouts
# (#1473). The mirror — populated by
# `.github/workflows/mirror-isabelle-distribution.yml` — wraps the
# upstream tarballs as `FROM scratch + COPY` images on GHCR, which the
# Blacksmith pool can already pull routinely. The wrapper images carry
# multi-platform manifest lists (`linux/amd64,linux/arm64`) so the
# `COPY --from=` lines below resolve regardless of the consumer's
# build platform.
#
# Bootstrap order: when `ISABELLE_VERSION` or `AFP_DATED_TAG` is bumped
# here, the mirror workflow MUST be re-dispatched first
# (`gh workflow run mirror-isabelle-distribution.yml`) to populate the
# matching GHCR tags. The base build will fail with "manifest not
# found" otherwise. This is the cost of the mirror's hermetic-build
# guarantee; the alternative was the silent-timeout failure mode of
# #1473.

ARG TARGETARCH
ARG ISABELLE_VERSION=Isabelle2025-2
# SHA-256 of the upstream Isabelle distribution tarball (amd64;
# `Isabelle2025-2_linux.tar.gz` from isabelle.in.tum.de/dist), checked
# below before extract. The mirror copies the tarball verbatim, so this
# single pin catches corruption at either hop (upstream->mirror and
# mirror->build). Upstream ships no published SHA file; recompute on a
# version bump with `curl -sL <upstream-url> | sha256sum`.
ARG ISABELLE_SHA256=a20a507bc7c1270d8be96a9f3fbec06345387789d2dc2c4d3df6260d47bfb33c

# AFP release pinned by dated tag for reproducibility (#1022). The
# DATED tag `afp-2026-06-01` is the correct pin shape: rolling tags
# like `afp-current` always serve the latest AFP, which would make the
# SHA pin mismatch the contents the moment AFP rolls. The dated tag is
# content-stable forever and matches the pinned `ISABELLE_VERSION`.
#
# AFP / Isabelle pairing: this AFP archive MUST target the same Isabelle
# version as `ISABELLE_VERSION`, else the `Complex_Bounded_Operators`
# heap bake fails with "Missing session sources entry". The dated tag
# alone is NOT a reliable signal (some 2026-dated archives track the
# Isabelle 2026 pre-release) — verify the tarball's own `etc/version`:
#
#   curl -sL https://isa-afp.org/release/<tag>.tar.gz \
#     | tar xzO --wildcards '*/etc/version' | grep '^VERSION='
#
# `afp-2026-06-01` reports `VERSION=2025-2`, matching Isabelle2025-2.
#
# Future AFP refreshes: pick a dated tag whose `etc/version` matches the
# bumped `ISABELLE_VERSION`, recompute `AFP_SHA256` via
# `curl -sL <upstream-url> | sha256sum`, and update `AFP_DIRNAME` if the
# tarball's top-level dir naming differs. Then just edit these ARGs and
# open a PR — merging republishes the source mirror tag and rebuilds the
# base automatically (see build-isabelle-base-image.yml BUMP ORDERING).
ARG AFP_DATED_TAG=afp-2026-06-01
ARG AFP_SHA256=872f85ed0d026bfd13940a3f76c6a8cd0e995c2f7c895dbd4671e84bc6ce39d0
ARG AFP_DIRNAME=afp-2026-06-01

# Mirror image refs. Parameterised so the workflow can override during
# bootstrap (e.g. point at a personal fork's GHCR namespace for local
# CI work). Defaults are the production GIDE mirror, lowercased per
# GHCR's RFC 5891 enforcement (#1473 bug fix).
ARG ISABELLE_MIRROR_IMAGE=ghcr.io/darcstar-technologies/gide-isabelle-source
ARG AFP_MIRROR_IMAGE=ghcr.io/darcstar-technologies/gide-afp-source

# Stage 1: pull the per-arch Isabelle tarball from the GHCR mirror.
# The wrapper is `FROM scratch + COPY distribution.tar.gz /` — no
# binaries to execute, just the tarball at a known path. Per-arch
# differentiation is encoded in the TAG (`-amd64` vs `-arm64`); the
# wrapper's multi-platform manifest list lets `COPY --from` resolve
# regardless of the consumer's build platform.
FROM ${ISABELLE_MIRROR_IMAGE}:${ISABELLE_VERSION}-${TARGETARCH} AS isabelle-mirror

# Stage 2: pull the AFP tarball. AFP source is architecture-
# independent so the mirror tag is single (no `-amd64`/`-arm64`
# suffix); the wrapper itself is still a multi-platform manifest list.
FROM ${AFP_MIRROR_IMAGE}:${AFP_DATED_TAG} AS afp-mirror

# Stage 3: heap-builder. Extracts the tarballs and runs the slow CBO heap
# bake. Pinned to its OWN Ubuntu digest, bumped only on an Isabelle/AFP
# version change or a major Ubuntu jump — NOT routine CVE refreshes (those
# move only the runtime base in stage 4). Keeping this digest stable is
# what lets the registry buildcache skip the 90-150 min bake when only the
# runtime base changes. This stage is never shipped.
FROM ubuntu:26.04@sha256:f3d28607ddd78734bb7f71f117f3c6706c666b8b76cbff7c9ff6e5718d46ff64 AS heap-builder
ARG TARGETARCH
ARG ISABELLE_VERSION
ARG ISABELLE_SHA256
ARG AFP_SHA256
ARG AFP_DIRNAME

COPY --from=isabelle-mirror /distribution.tar.gz /tmp/isabelle.tar.gz
COPY --from=afp-mirror /afp.tar.gz /tmp/afp.tar.gz

# Install only what's strictly needed for the bake. `curl` is NOT in
# this list (was needed pre-mirror for the upstream downloads; now
# the tarballs arrive via `COPY --from=`). `ca-certificates` stays
# for apt-get's own HTTPS to the Ubuntu archive. `fontconfig` and
# `libgomp1` are Isabelle runtime requirements.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates fontconfig libgomp1 && \
    useradd -m isabelle && \
    # Verify the Isabelle distribution tarball against the pinned
    # SHA-256 before extracting. The mirror wrapper is `FROM scratch +
    # COPY` (verbatim bytes), so this one check covers both the
    # upstream->mirror and mirror->build hops. Upstream ships no
    # published SHA file, so ISABELLE_SHA256 is computed at pin-bump time.
    echo "${ISABELLE_SHA256}  /tmp/isabelle.tar.gz" | sha256sum -c - && \
    cd /opt && tar xzf /tmp/isabelle.tar.gz && rm /tmp/isabelle.tar.gz && \
    ln -s /opt/${ISABELLE_VERSION} /opt/isabelle && \
    chown -R isabelle:isabelle /opt/${ISABELLE_VERSION} && \
    # Extract AFP under /opt/afp/<dated-dir> with stable symlink
    # /opt/afp/thys. Defense-in-depth SHA-256 verify against the
    # mirrored tarball — the mirror workflow verified the same SHA
    # against upstream before pushing, so this is a redundant check
    # against in-flight registry-side corruption. Cheap; keep it.
    mkdir -p /opt/afp && cd /opt/afp && \
    echo "${AFP_SHA256}  /tmp/afp.tar.gz" | sha256sum -c - && \
    tar xzf /tmp/afp.tar.gz && rm /tmp/afp.tar.gz && \
    ln -s /opt/afp/${AFP_DIRNAME}/thys /opt/afp/thys && \
    chown -R isabelle:isabelle /opt/afp && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

ENV PATH="/opt/isabelle/bin:${PATH}"
USER isabelle
WORKDIR /home/isabelle

# Register AFP with Isabelle's session resolver via the per-user ROOTS
# file (each line = a directory containing session ROOT/ROOTS files;
# /opt/afp/thys/ROOTS lists all AFP sessions). Required so
# `isabelle build Complex_Bounded_Operators` can find the AFP sources.
# The overlay extends this ROOTS file to also include Layer1..Layer5.
#
# Force 64-bit PolyML (`x86_64-linux`; default picks `x86_64_32-linux`
# which caps virtual address space at 4 GB and OOMs on the CBO heap-save
# step). 64-bit heaps are ~50% larger so HOL-Analysis peak hits ~5-6 GB.
# The CBO bake below runs `-j 1` (one session at a time) so peak stays
# around 6 GB — comfortable headroom on the free GitHub-hosted
# `ubuntu-24.04` runner (16 GB) that `build-isabelle-base-image.yml` uses.
RUN mkdir -p ~/.isabelle/${ISABELLE_VERSION}/etc && \
    echo "/opt/afp/thys" > ~/.isabelle/${ISABELLE_VERSION}/ROOTS && \
    case "$TARGETARCH" in \
      amd64) ML_PLATFORM="x86_64-linux" ;; \
      *) echo "isabelle-base is amd64-only (bundled PolyML SIGILLs on ${TARGETARCH:-<unset>}); refusing to build" >&2; exit 1 ;; \
    esac && \
    printf '%s\n' \
        "ML_PLATFORM=\"${ML_PLATFORM}\"" \
        'ML_HOME="$POLYML_HOME/$ML_PLATFORM"' \
        'ML_OPTIONS="--minheap 2G --maxheap 6G"' \
        > ~/.isabelle/${ISABELLE_VERSION}/etc/settings
# Pre-build Complex_Bounded_Operators (transitively builds HOL-Analysis,
# Jordan_Normal_Form, Banach_Steinhaus, Real_Impl, Wlog, HOL-Examples,
# HOL-Types_To_Sets, Mersenne_Primes) so theories that need complex
# Hilbert / cblinfun / selfadjoint / unitary machinery (T008 part-(a)
# chain mirror, future graduations) can `imports
# Complex_Bounded_Operators.<...>` without rebuilding the heap on every
# CI invocation.
#
# Also pre-build Ordinary_Differential_Equations (gide-public-images #17)
# so the overlay can `imports Ordinary_Differential_Equations.Gronwall`
# (the continuous Gronwall inequality, AFP Library/Gronwall.thy) without
# compiling the ODE session on every overlay bake — the same rationale
# that keeps the CBO heap here rather than in the fast, dev-driven overlay
# layer. Consumer: gide#2122 graduates the
# `lyapunov_dissipation_to_trajectory_bound` proof from Lean-only to a
# mirrored Isabelle proof. ODE's base session is parented on HOL-Analysis,
# which the CBO bake already builds, so we do NOT pay for a fresh
# HOL-Analysis. The incremental cost is the ODE base session itself plus
# the support sessions it pulls that the CBO set lacks — currently
# HOL-Decision_Procs (distribution), Triangle, List-Index and
# Affine_Arithmetic (AFP, the non-trivial one). The heavier rigorous-
# numerics sessions (HOL-ODE-Numerics, Lorenz_*) and their Collections
# dependency are deliberately NOT built: only the base
# Ordinary_Differential_Equations session, which contains Gronwall, is
# needed (gpi#17 non-goals).
#
# Both sessions go to ONE `isabelle build -b` invocation so shared
# dependencies (HOL-Analysis, …) are built exactly once. `-j 1` runs
# sessions one at a time, so peak memory stays around 6 GB (one 6 GB heap
# cap) — safe on the free 16 GB runner. Cold build ~90-150 min for the CBO
# chain plus the ODE-session delta (wall-time + image-size delta recorded
# in the publishing run, per gpi#17 / gide#2122 acceptance criteria); warm
# rebuilds (registry buildcache) hit the cached layer. Issues #1022, gpi#17.
#
# `-o timeout_scale=2.0` doubles all declared session timeouts so the
# build survives slow CI hardware. `Complex_Bounded_Operators/ROOT`
# pins `timeout = 1800` (30 min) on AFP's reference machine; the
# GitHub-hosted runner clocks the build at "factor 0.73" (about 37%
# slower), which makes CBO need ~41 min wall and trip the declared
# timeout. Doubling gives a 60 min ceiling, comfortably above what
# this hardware actually needs while still surfacing a real hang. The
# same scale covers the ODE session's declared timeouts.
RUN isabelle build -j 1 -o timeout_scale=2.0 -b Complex_Bounded_Operators Ordinary_Differential_Equations

# Stage 4: shipped image. Thin Ubuntu runtime + the baked Isabelle install
# and CBO + ODE heaps COPYed from the builder. This is the ONLY stage on a
# CVE-patched base, so an Ubuntu digest bump here rebuilds just these few
# layers (cache-hitting the heap-builder stage above) instead of re-running
# the 90-150 min CBO bake. Runtime deps only: fontconfig + libgomp1 are
# Isabelle runtime requirements; ca-certificates for completeness.
#
# The `# renovate-runtime-base ubuntu` marker below is what the custom
# Renovate manager in renovate.json targets — the built-in dockerfile
# manager is disabled for this file so it can't bump BOTH ubuntu pins (and
# re-invalidate the cached bake). Only this runtime digest auto-updates.
# renovate-runtime-base ubuntu
FROM ubuntu:26.04@sha256:f3d28607ddd78734bb7f71f117f3c6706c666b8b76cbff7c9ff6e5718d46ff64

# OCI image metadata. `image.source` links this package to its repo on
# GHCR; `image.description` documents the contents. Living in the thin
# final stage means editing labels (or patching the runtime base) never
# invalidates the cached heap-builder, so the 90-150 min CBO bake is
# skipped on a runtime-only change.
LABEL org.opencontainers.image.source="https://github.com/DarcStar-Technologies/gide-public-images" \
      org.opencontainers.image.description="Isabelle + AFP + pre-baked Complex_Bounded_Operators and Ordinary_Differential_Equations heaps (toolchain base; amd64)"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates fontconfig libgomp1 && \
    useradd -m isabelle && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# Bring over the baked Isabelle install + AFP (/opt) and the per-user
# config + saved heaps (~/.isabelle). --chown re-stamps ownership to the
# runtime image's isabelle user.
COPY --from=heap-builder --chown=isabelle:isabelle /opt /opt
COPY --from=heap-builder --chown=isabelle:isabelle /home/isabelle/.isabelle /home/isabelle/.isabelle

ENV PATH="/opt/isabelle/bin:${PATH}"
USER isabelle
WORKDIR /home/isabelle
ENTRYPOINT ["isabelle"]
