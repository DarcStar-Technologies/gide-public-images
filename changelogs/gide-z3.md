# Changelog — `gide-z3`

Publish history for `ghcr.io/darcstar-technologies/gide-z3` (Z3 SMT solver
binary on a minimal base; **amd64 + arm64**). Format and conventions: see the
[root CHANGELOG](../CHANGELOG.md). Licenses:
[THIRD-PARTY-NOTICES](../THIRD-PARTY-NOTICES.md).

## [4.16.0] — 2026-06-03
**Digest:** `sha256:1e3437a8ad7f3e92602b7cb124ce2850ceb331857ed51e318b5276fedb4ea66e`

### Upstream
- Z3 `4.16.0` — [release notes](https://github.com/Z3Prover/z3/releases/tag/z3-4.16.0) (MIT)

### Composition (this repo)
- The upstream release archive (`z3-4.16.0-<plat>.zip`) extracted onto a minimal
  base; OCI `image.source` + `image.description` labels; smoke-tested with
  `--version` before promotion. Trivy-scanned by `scan-published-images.yml`.
- Auto-tracked by Renovate (github-releases). Initial published build (baseline).

### Provenance
- git `908b562` · SLSA provenance + SPDX SBOM attached at publish
- `docker pull ghcr.io/darcstar-technologies/gide-z3@sha256:1e3437a8ad7f3e92602b7cb124ce2850ceb331857ed51e318b5276fedb4ea66e`
