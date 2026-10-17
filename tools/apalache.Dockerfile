FROM eclipse-temurin:25.0.4_7-jre-noble@sha256:b4c93a50fc67612798db73d68ca3b0ee4ebdd51736e59cca370e689b9797037e
# Apalache TLA+ symbolic model checker. Ships as a JVM tarball
# (apalache.tgz / apalache-X.Y.Z.tgz) containing bin/ scripts + lib/
# JARs, so the same artifact is portable to amd64 and arm64. The base
# image (eclipse-temurin:17-jre-noble) is a multi-arch manifest, so
# this Dockerfile is fully arch-agnostic.
#
# Why noble (Ubuntu 24.04) instead of jammy (Ubuntu 22.04): the jammy
# variant SIGSEGVs in libc-bin's post-installation script under QEMU
# arm64 emulation (`subprocess returned error exit status 139`),
# which is a well-known glibc 2.35 + QEMU interaction bug. noble
# ships glibc 2.39 which sidesteps the bug, and the other small
# prover images (z3, cvc5) already build cleanly on a 24.04 base
# under the same QEMU setup.
ARG TARGETARCH
ARG APALACHE_VERSION=0.58.2
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl && \
    curl -fsSL --retry 5 --retry-delay 5 --retry-max-time 60 \
        --retry-all-errors --retry-connrefused \
        "https://github.com/apalache-mc/apalache/releases/download/v${APALACHE_VERSION}/apalache-${APALACHE_VERSION}.tgz" -o /tmp/apalache.tgz && \
    tar xzf /tmp/apalache.tgz -C /opt && \
    mv "/opt/apalache-${APALACHE_VERSION}" /opt/apalache && \
    ln -s /opt/apalache/bin/apalache-mc /usr/local/bin/apalache && \
    # Apalache writes scratch state under /var/apalache by convention;
    # pre-create it world-writable so the consumer wrapper
    # (`tools/apalache`) can bind-mount over it without uid surprises.
    mkdir -p /var/apalache && chmod 0777 /var/apalache && \
    apt-get purge -y curl && apt-get autoremove -y && \
    rm -rf /tmp/apalache.tgz /var/lib/apt/lists/*
LABEL org.opencontainers.image.source="https://github.com/DarcStar-Technologies/gide-public-images" \
      org.opencontainers.image.description="Apalache TLA+ model checker"
# Match the entrypoint the existing host wrapper expects:
# `docker run ... <image> version`, `docker run ... <image> check ...`.
ENTRYPOINT ["apalache"]
