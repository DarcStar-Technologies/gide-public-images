FROM ubuntu:26.04@sha256:f3d28607ddd78734bb7f71f117f3c6706c666b8b76cbff7c9ff6e5718d46ff64
# Lean4 BASE image: Ubuntu + elan + Lean4 toolchain + pre-compiled Mathlib.
# This is the slow, upstream-driven layer (`LEAN4_TOOLCHAIN` and
# `MATHLIB_REV` cold-build is 30-60 min per arch). It is rebuilt when
# upstream Lean4 / Mathlib bumps land, when this Dockerfile changes, or
# on a weekly cron for Ubuntu CVE refreshes.
#
# The theorem-augmented overlay (`tools/lean4.Dockerfile`) bakes
# `proofs/Shared/**` source + pre-built oleans on top of this base. By
# splitting the two layers, a `proofs/Shared/**` edit only rebuilds the
# overlay (~seconds) instead of the full Mathlib bake.
#
# Multi-arch: TARGETARCH is auto-populated by buildx. The Lean4
# toolchain (via elan) and Mathlib both publish native aarch64-linux
# artifacts, so this Dockerfile is arch-agnostic; the multi-arch
# manifest is assembled by the workflow (`build-lean4-base-image.yml`).
ARG LEAN4_TOOLCHAIN=leanprover/lean4:v4.30.0
ARG MATHLIB_REV=v4.30.0
ARG TARGETARCH

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl git && \
    useradd -m lean && \
    su lean -c "curl -sSf https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh | sh -s -- -y --default-toolchain ${LEAN4_TOOLCHAIN}" && \
    rm -rf /var/lib/apt/lists/*
# Keep curl and git available: Mathlib's `lake update` post-hook invokes
# `lake exe cache get` which uses curl to fetch pre-compiled oleans, and
# the same network round-trip is exercised on the overlay's `lake build`.
ENV PATH="/home/lean/.elan/bin:${PATH}"
USER lean

# Bootstrap a Lake project that depends on Mathlib4 so proof files can
# `import Mathlib.*`. Mathlib is pre-compiled at image-build time so
# per-proof invocations hit the cache (~30-60 min one-time build cost).
#
# The lakefile also declares `lean_lib Shared` (issue #1082 Phase 3) so
# the overlay's `lake build Shared` resolves cleanly without re-emitting
# the declaration. The overlay's COPY + `lake build Shared` populates
# the source + oleans on top of this base.
WORKDIR /home/lean/proof-env
RUN printf 'import Lake\nopen Lake DSL\n\npackage «gide-proofs»\n\nrequire mathlib from git "https://github.com/leanprover-community/mathlib4.git" @ "%s"\n\nlean_lib Shared where\n  srcDir := "."\n  globs := #[.submodules `Shared]\n' "$MATHLIB_REV" > lakefile.lean && \
    echo "$LEAN4_TOOLCHAIN" > lean-toolchain && \
    lake update && \
    lake build

# Probe so a misconfigured toolchain surfaces here rather than at first
# wrapper invocation.
RUN lean --version

# OCI metadata. Placed after the Mathlib bake so editing labels (or
# patching anything below) never invalidates the ~30-60 min build.
# `image.source` links this package to its repo on GHCR.
LABEL org.opencontainers.image.source="https://github.com/DarcStar-Technologies/gide-public-images" \
      org.opencontainers.image.description="Lean4 toolchain + pre-compiled Mathlib4 (toolchain base)"

# Default entrypoint matches the overlay so `docker run gide-lean4-base`
# behaves identically to the published `gide-lean4` image when no
# Shared bake is needed (e.g. ad-hoc Mathlib-only experiments).
ENTRYPOINT ["lake", "env", "lean"]
