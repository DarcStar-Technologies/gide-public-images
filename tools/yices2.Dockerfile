FROM ubuntu:26.04@sha256:f3d28607ddd78734bb7f71f117f3c6706c666b8b76cbff7c9ff6e5718d46ff64
# Yices2 upstream only publishes a Linux x86_64 static binary
# (yices-X.Y.Z-x86_64-pc-linux-gnu-static-gmp.tar.gz). No arm64 Linux
# release artifact exists. The build workflow restricts platforms to
# linux/amd64; this Dockerfile guards against accidental arm64 builds.
ARG TARGETARCH
ARG YICES2_VERSION=2.6.5
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl && \
    case "$TARGETARCH" in \
      amd64) : ;; \
      *) echo "yices2 image only supports linux/amd64 (no upstream arm64 binary); got TARGETARCH=${TARGETARCH:-<unset>}" >&2; exit 1 ;; \
    esac && \
    curl -fsSL --retry 5 --retry-delay 5 --retry-max-time 60 \
        --retry-all-errors --retry-connrefused \
        "https://github.com/SRI-CSL/yices2/releases/download/Yices-${YICES2_VERSION}/yices-${YICES2_VERSION}-x86_64-pc-linux-gnu-static-gmp.tar.gz" -o /tmp/yices2.tar.gz && \
    tar xzf /tmp/yices2.tar.gz -C /opt && \
    ln -s /opt/yices-${YICES2_VERSION}/bin/yices-smt2 /usr/local/bin/yices-smt2 && \
    apt-get purge -y curl && apt-get autoremove -y && \
    rm -rf /tmp/yices2.tar.gz /var/lib/apt/lists/*
LABEL org.opencontainers.image.source="https://github.com/DarcStar-Technologies/gide-public-images" \
      org.opencontainers.image.description="Yices2 SMT solver"
ENTRYPOINT ["yices-smt2"]
