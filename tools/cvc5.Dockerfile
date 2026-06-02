FROM ubuntu:26.04@sha256:f3d28607ddd78734bb7f71f117f3c6706c666b8b76cbff7c9ff6e5718d46ff64
# `TARGETARCH` is set by buildx (`amd64` | `arm64`). cvc5 v1.2.0+
# publishes native Linux static binaries for both arches.
ARG TARGETARCH
ARG CVC5_VERSION=1.3.4
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl unzip && \
    case "$TARGETARCH" in \
      amd64) CVC5_PLAT="x86_64" ;; \
      arm64) CVC5_PLAT="arm64" ;; \
      *) echo "Unsupported TARGETARCH: ${TARGETARCH:-<unset>}" >&2; exit 1 ;; \
    esac && \
    curl -fsSL --retry 5 --retry-delay 5 --retry-max-time 60 \
        --retry-all-errors --retry-connrefused \
        "https://github.com/cvc5/cvc5/releases/download/cvc5-${CVC5_VERSION}/cvc5-Linux-${CVC5_PLAT}-static.zip" -o /tmp/cvc5.zip && \
    unzip -q /tmp/cvc5.zip -d /opt && \
    mv "/opt/cvc5-Linux-${CVC5_PLAT}-static/bin/cvc5" /usr/local/bin/cvc5 && \
    chmod +x /usr/local/bin/cvc5 && \
    apt-get purge -y curl unzip && apt-get autoremove -y && \
    rm -rf "/tmp/cvc5.zip" "/opt/cvc5-Linux-${CVC5_PLAT}-static" /var/lib/apt/lists/*
LABEL org.opencontainers.image.source="https://github.com/DarcStar-Technologies/gide-public-images" \
      org.opencontainers.image.description="cvc5 SMT solver"
ENTRYPOINT ["cvc5"]
