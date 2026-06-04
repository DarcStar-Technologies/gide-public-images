# Changelog — `gide-apalache`

Publish history for `ghcr.io/darcstar-technologies/gide-apalache` (Apalache TLA+
symbolic model checker on a minimal base; **amd64 + arm64**). Format and
conventions: see the [root CHANGELOG](../CHANGELOG.md). Licenses:
[THIRD-PARTY-NOTICES](../THIRD-PARTY-NOTICES.md).

<!-- renovate-pr-42 -->
## [0.58.0] — 2026-06-04
**Digest:** _published on merge — see GitHub Release `gide-apalache-0.58.0`._

### Composition (this repo)
- Bumped to `0.58.0` (from `0.57.0`) via Renovate (#42). Upstream release notes are in PR #42; the published digest + provenance land in the GitHub Release on merge.


## [0.57.0] — 2026-06-03
**Digest:** `sha256:4d903363c8ef50baa6debb970c6022135bd93d285aff61db26c85883689ac609`

### Upstream
- Apalache `0.57.0` — [release notes](https://github.com/apalache-mc/apalache/releases/tag/v0.57.0) (Apache-2.0)

### Composition (this repo)
- The upstream release (`apalache-0.57.0.tgz`, JVM) extracted onto a minimal base
  with a JRE; OCI `image.source` + `image.description` labels; smoke-tested with
  `version` before promotion. Trivy-scanned by `scan-published-images.yml`.
- Auto-tracked by Renovate (github-releases). Initial published build (baseline).
  Renovate currently has a `0.57.0 → 0.58.0` bump queued
  ([#21](https://github.com/DarcStar-Technologies/gide-public-images/issues/21)).

### Provenance
- git `908b562` · SLSA provenance + SPDX SBOM attached at publish
- `docker pull ghcr.io/darcstar-technologies/gide-apalache@sha256:4d903363c8ef50baa6debb970c6022135bd93d285aff61db26c85883689ac609`
