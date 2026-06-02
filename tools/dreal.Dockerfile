FROM ubuntu:26.04@sha256:f3d28607ddd78734bb7f71f117f3c6706c666b8b76cbff7c9ff6e5718d46ff64
# dReal δ-complete SMT solver. Upstream's last release (dreal4
# 4.21.06.2, July 2021) only ships .deb packages for Ubuntu 20.04
# (focal); newer Ubuntu series and arm64 are unsupported by the
# upstream release pipeline.
#
# Install path (matches dReal4's setup/ubuntu/20.04/install.sh
# upstream script):
#   1. Configure ppa:dreal/dreal as an apt source. The PPA only
#      ships dreal's custom `libibex-dev` runtime dep, NOT the
#      dreal package itself; `apt-get install dreal` would fail
#      ("Unable to locate package dreal").
#   2. Download the dreal_X.Y.Z_amd64.deb from the GitHub release.
#   3. `apt-get install ./dreal.deb` so apt resolves libibex-dev
#      from the PPA in the same transaction as dreal from the
#      local .deb file. dpkg -i alone would refuse with unmet
#      dependencies.
#
# The build workflow restricts platforms to linux/amd64; this
# Dockerfile guards against accidental arm64 builds with a
# TARGETARCH case statement.
ARG TARGETARCH
ARG DREAL_VERSION=4.21.06.2
# DEBIAN_FRONTEND=noninteractive prevents tzdata from blocking on
# console input during the unattended image build.
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl gnupg && \
    case "$TARGETARCH" in \
      amd64) : ;; \
      *) echo "dreal image only supports linux/amd64 (no upstream arm64 build); got TARGETARCH=${TARGETARCH:-<unset>}" >&2; exit 1 ;; \
    esac && \
    # Configure ppa:dreal/dreal as an apt source so libibex-dev is
    # resolvable. Sign with the PPA's signing key fingerprint
    # (verified via the Launchpad API).
    install -m 0755 -d /etc/apt/keyrings && \
    # NOTE: --retry-all-errors was added in curl 7.71; ubuntu:20.04
    # ships curl 7.68, so use the smaller retry flag set 7.68 supports.
    curl -fsSL --retry 5 --retry-delay 5 --retry-max-time 60 \
        --retry-connrefused \
        "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x019AEC397A4FCBEDC4430E857BAD267FFE61A85C" \
        | gpg --dearmor -o /etc/apt/keyrings/dreal.gpg && \
    chmod 0644 /etc/apt/keyrings/dreal.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/dreal.gpg] https://ppa.launchpadcontent.net/dreal/dreal/ubuntu focal main" \
        > /etc/apt/sources.list.d/dreal.list && \
    apt-get update && \
    # Fetch the dreal .deb from the GitHub release. The release
    # endpoint is highly reliable, but stay conservative on retries.
    curl -fsSL --retry 5 --retry-delay 5 --retry-max-time 60 \
        --retry-connrefused \
        "https://github.com/dreal/dreal4/releases/download/${DREAL_VERSION}/dreal_${DREAL_VERSION}_amd64.deb" \
        -o /tmp/dreal.deb && \
    # `apt-get install ./local.deb` (vs. `dpkg -i`) makes apt resolve
    # libibex-dev from the PPA and link it with the dreal package
    # graph in a single transaction.
    apt-get install -y --no-install-recommends /tmp/dreal.deb && \
    # The .deb installs the binary at /opt/dreal/${DREAL_VERSION}/bin/dreal
    # but its postinst does NOT register a /usr/bin/dreal shim (that step
    # only runs when dReal4's setup/ubuntu/<series>/install.sh is used to
    # provision the host). The host wrapper (`tools/dreal`) invokes
    # `docker run ... dreal ...` and therefore needs `dreal` on PATH, so
    # we symlink it explicitly into /usr/local/bin (issue surfaced by the
    # ci-prover-portfolio wrapper smoke check).
    ln -s /opt/dreal/${DREAL_VERSION}/bin/dreal /usr/local/bin/dreal && \
    apt-get purge -y curl gnupg && \
    apt-get autoremove -y && \
    rm -rf /tmp/dreal.deb /var/lib/apt/lists/*
LABEL org.opencontainers.image.source="https://github.com/DarcStar-Technologies/gide-public-images" \
      org.opencontainers.image.description="dReal delta-complete SMT solver"
ENTRYPOINT ["dreal"]
