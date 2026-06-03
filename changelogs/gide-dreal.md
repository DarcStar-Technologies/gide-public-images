# Changelog — `gide-dreal`

Publish history for `ghcr.io/darcstar-technologies/gide-dreal` (dReal
delta-complete SMT solver on a minimal base; **amd64-only** — upstream ships an
`amd64` `.deb`). Format and conventions: see the [root CHANGELOG](../CHANGELOG.md).
Licenses: [THIRD-PARTY-NOTICES](../THIRD-PARTY-NOTICES.md).

## [4.21.06.2] — 2026-06-03
**Digest:** `sha256:1e5e4850745ea7a907b20df35a30b556fe3ee412b5e66ded7b0379f220699888`

### Upstream
- dReal `4.21.06.2` — [release notes](https://github.com/dreal/dreal4/releases/tag/4.21.06.2) (Apache-2.0)

### Composition (this repo)
- The upstream package (`dreal_4.21.06.2_amd64.deb`) installed onto a minimal
  base; OCI `image.source` + `image.description` labels; smoke-tested with
  `--version` before promotion. Trivy-scanned by `scan-published-images.yml`.
- Auto-tracked by Renovate (github-releases). Initial published build (baseline).

### Provenance
- git `908b562` · SLSA provenance + SPDX SBOM attached at publish
- `docker pull ghcr.io/darcstar-technologies/gide-dreal@sha256:1e5e4850745ea7a907b20df35a30b556fe3ee412b5e66ded7b0379f220699888`
