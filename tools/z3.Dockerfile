FROM ubuntu:26.04@sha256:f3d28607ddd78734bb7f71f117f3c6706c666b8b76cbff7c9ff6e5718d46ff64
# `TARGETARCH` is set by buildx (`amd64` | `arm64`). Z3 publishes native
# Linux binaries for both arches via separate release artifacts; the
# glibc version embedded in the artifact name differs (2.39 for amd64,
# 2.38 for arm64 in v4.16.0), so the URL is computed at RUN time.
ARG TARGETARCH
ARG Z3_VERSION=5.0.0
ARG Z3_GLIBC_AMD64=2.39
ARG Z3_GLIBC_ARM64=2.38
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl unzip && \
    case "$TARGETARCH" in \
      amd64) Z3_PLAT="x64-glibc-${Z3_GLIBC_AMD64}" ;; \
      arm64) Z3_PLAT="arm64-glibc-${Z3_GLIBC_ARM64}" ;; \
      *) echo "Unsupported TARGETARCH: ${TARGETARCH:-<unset>}" >&2; exit 1 ;; \
    esac && \
    curl -fsSL --retry 5 --retry-delay 5 --retry-max-time 60 \
        --retry-all-errors --retry-connrefused \
        "https://github.com/Z3Prover/z3/releases/download/z3-${Z3_VERSION}/z3-${Z3_VERSION}-${Z3_PLAT}.zip" -o /tmp/z3.zip && \
    unzip -q /tmp/z3.zip -d /opt && \
    mv "/opt/z3-${Z3_VERSION}-${Z3_PLAT}" /opt/z3 && \
    ln -s /opt/z3/bin/z3 /usr/local/bin/z3 && \
    apt-get purge -y curl unzip && apt-get autoremove -y && \
    rm -rf /tmp/z3.zip /var/lib/apt/lists/*
LABEL org.opencontainers.image.source="https://github.com/DarcStar-Technologies/gide-public-images" \
      org.opencontainers.image.description="Z3 SMT solver"
ENTRYPOINT ["z3"]
