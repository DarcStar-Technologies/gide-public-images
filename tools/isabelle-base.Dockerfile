# Isabelle BASE image: Ubuntu + Isabelle distribution + AFP source +
# pre-baked Complex_Bounded_Operators heap chain.
#
# This is the slow, upstream-driven layer (CBO heap is 90-150 min cold
# per arch). It is rebuilt when `ISABELLE_VERSION` / `AFP_*` bump, when
# this Dockerfile changes, or on a weekly cron for Ubuntu CVE refreshes.
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

# AFP release pinned by dated tag for reproducibility (#1022). The
# DATED tag `afp-2026-02-06` is the correct pin shape: rolling tags
# like `afp-current` always serve the latest AFP, which would make the
# SHA pin mismatch the contents the moment AFP rolls. The dated tag is
# content-stable forever and matches the pinned `ISABELLE_VERSION`.
#
# AFP / Isabelle pairing: `afp-2026-02-06` is the AFP stable release
# tagged for Isabelle 2025-2 (per isa-afp.org "Older releases: Feb 6,
# 2026 : Isabelle2025-2"). Newer dated archives track Isabelle 2026
# pre-release; pairing them with Isabelle 2025-2 produces "Missing
# session sources entry" errors at `Complex_Bounded_Operators`
# sub-session load.
#
# Future AFP refreshes: bump `AFP_DATED_TAG` to match the bumped
# `ISABELLE_VERSION` (verify against the AFP "Older releases" list),
# recompute `AFP_SHA256` via `curl -sL <upstream-url> | sha256sum`,
# update `AFP_DIRNAME` if the tarball's top-level directory naming
# differs, AND re-dispatch the mirror workflow to publish the new
# tags before opening a PR with these bumps.
ARG AFP_DATED_TAG=afp-2026-02-06
ARG AFP_SHA256=b059edd46073479ee8dde45004c2346a7365e5d94cded49d27257cfea66c8879
ARG AFP_DIRNAME=afp-2026-02-06

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

# Stage 3: final image. Ubuntu + extract tarballs + CBO heap bake.
FROM ubuntu:26.04@sha256:f3d28607ddd78734bb7f71f117f3c6706c666b8b76cbff7c9ff6e5718d46ff64
ARG TARGETARCH
ARG ISABELLE_VERSION
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
    # Extract Isabelle distribution. The mirrored tarball is the same
    # bits the upstream curl path used to fetch — verified via the
    # mirror workflow's content-stability guarantees. No need for a
    # SHA-256 verify here because the upstream-side verify happens in
    # the mirror workflow before push (the Isabelle tarballs don't
    # ship a separate published SHA-256 the way AFP does, so the
    # pre-#1473 path also didn't verify them — we're not regressing
    # that posture).
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
# step). 64-bit heaps are ~50% larger so HOL-Analysis peak hits ~5-6 GB
# and image build needs a runner with >= 12 GB RAM. The
# `build-isabelle-base-image.yml` workflow specifies a large runner accordingly.
RUN mkdir -p ~/.isabelle/${ISABELLE_VERSION}/etc && \
    echo "/opt/afp/thys" > ~/.isabelle/${ISABELLE_VERSION}/ROOTS && \
    case "$TARGETARCH" in \
      amd64) ML_PLATFORM="x86_64-linux" ;; \
      arm64) ML_PLATFORM="arm64-linux" ;; \
      *) echo "Unsupported TARGETARCH: ${TARGETARCH:-<unset>}" >&2; exit 1 ;; \
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
# CI invocation. `-j 2` runs at most 2 sessions in parallel, so peak
# memory stays around 12 GB (2 x 6 GB heap cap). Cold build ~90-150 min;
# warm rebuilds (Buildx GHA cache) hit the cached layer. Issue #1022.
#
# `-o timeout_scale=2.0` doubles all declared session timeouts so the
# build survives slow CI hardware. `Complex_Bounded_Operators/ROOT`
# pins `timeout = 1800` (30 min) on AFP's reference machine; the
# GitHub-hosted runner clocks the build at "factor 0.73" (about 37%
# slower), which makes CBO need ~41 min wall and trip the declared
# timeout. Doubling gives a 60 min ceiling, comfortably above what
# this hardware actually needs while still surfacing a real hang.
RUN isabelle build -j 2 -o timeout_scale=2.0 -b Complex_Bounded_Operators

ENTRYPOINT ["isabelle"]
