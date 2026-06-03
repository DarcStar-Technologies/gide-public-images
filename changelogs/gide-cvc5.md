# Changelog — `gide-cvc5`

Publish history for `ghcr.io/darcstar-technologies/gide-cvc5` (cvc5 SMT solver
binary on a minimal base; **amd64 + arm64**). Format and conventions: see the
[root CHANGELOG](../CHANGELOG.md). Licenses:
[THIRD-PARTY-NOTICES](../THIRD-PARTY-NOTICES.md).

## [1.3.4] — 2026-06-03
**Digest:** `sha256:408a48b7e43039849fa9b251a4336ce6f25434562377b107f2a4d114c1b3bd1e`

### Upstream
- cvc5 `1.3.4` — [release notes](https://github.com/cvc5/cvc5/releases/tag/cvc5-1.3.4) (BSD-3-Clause)

### Composition (this repo)
- The upstream static build (`cvc5-Linux-<plat>-static.zip`) extracted onto a
  minimal base; OCI `image.source` + `image.description` labels; smoke-tested
  with `--version` before promotion. Trivy-scanned by `scan-published-images.yml`.
- Auto-tracked by Renovate (github-releases). Initial published build (baseline).

### Provenance
- git `908b562` · SLSA provenance + SPDX SBOM attached at publish
- `docker pull ghcr.io/darcstar-technologies/gide-cvc5@sha256:408a48b7e43039849fa9b251a4336ce6f25434562377b107f2a4d114c1b3bd1e`
