# Changelog — `gide-yices2`

Publish history for `ghcr.io/darcstar-technologies/gide-yices2` (Yices 2 SMT
solver binary on a minimal base; **amd64-only** — upstream ships an
`x86_64`-static build). Format and conventions: see the
[root CHANGELOG](../CHANGELOG.md). Licenses:
[THIRD-PARTY-NOTICES](../THIRD-PARTY-NOTICES.md).

## [2.6.5] — 2026-06-03
**Digest:** `sha256:e98c26876bc6ccc2302bc740572aec1d0e4fc07a7b301592db120d8ef63ff56e`

### Upstream
- Yices 2 `2.6.5` — [release notes](https://github.com/SRI-CSL/yices2/releases/tag/Yices-2.6.5) (GPL-3.0)

### Composition (this repo)
- The upstream static build (`yices-2.6.5-x86_64-pc-linux-gnu-static-gmp.tar.gz`)
  extracted onto a minimal base; OCI `image.source` + `image.description` labels;
  smoke-tested with `--version` before promotion. Trivy-scanned by
  `scan-published-images.yml`. GPL-3.0 is shipped in its own image, not linked
  into anything else.
- Auto-tracked by Renovate (github-releases). Initial published build (baseline).

### Provenance
- git `908b562` · SLSA provenance + SPDX SBOM attached at publish
- `docker pull ghcr.io/darcstar-technologies/gide-yices2@sha256:e98c26876bc6ccc2302bc740572aec1d0e4fc07a7b301592db120d8ef63ff56e`
