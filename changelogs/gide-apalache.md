# Changelog — `gide-apalache`

Publish history for `ghcr.io/darcstar-technologies/gide-apalache` (Apalache TLA+
symbolic model checker on a minimal base; **amd64 + arm64**). Format and
conventions: see the [root CHANGELOG](../CHANGELOG.md). Licenses:
[THIRD-PARTY-NOTICES](../THIRD-PARTY-NOTICES.md).

<!-- renovate-pr-42 -->
<!-- renovate-pr-57 -->
<!-- renovate-pr-61 -->
<!-- renovate-pr-78 -->
## [0.58.2] — 2026-08-10
**Digest:** _published on merge — see GitHub Release `gide-apalache-0.58.2`._

### Composition (this repo)
- Base image / digest refresh via Renovate (#78) — no upstream version change. See PR #78.


## [0.58.2] — 2026-07-13
**Digest:** _published on merge — see GitHub Release `gide-apalache-0.58.2`._

### Composition (this repo)
- Base image / digest refresh via Renovate (#61) — no upstream version change. See PR #61.


## [0.58.2] — 2026-06-29
**Digest:** _published on merge — see GitHub Release `gide-apalache-0.58.2`._

### Upstream
- Apalache `0.58.2` — [release notes](https://github.com/apalache-mc/apalache/releases/tag/v0.58.2)

<details><summary>Upstream release notes (captured from PR #57)</summary>

### [`v0.58.2`](https://redirect.github.com/apalache-mc/apalache/blob/HEAD/CHANGES.md#0582---2026-06-22)

[Compare Source](https://redirect.github.com/apalache-mc/apalache/compare/v0.58.0...v0.58.2)

</details>

### Composition (this repo)
- Bumped to `0.58.2` (from `0.58.0`) via Renovate (#57).


## [0.58.0] — 2026-06-04
**Digest:** _published on merge — see GitHub Release `gide-apalache-0.58.0`._

### Upstream
- Apalache `0.58.0` — [release notes](https://github.com/apalache-mc/apalache/releases/tag/v0.58.0)

<details><summary>Upstream release notes (backfilled from the upstream release)</summary>

## 0.58.0 - 2026-05-29

### Features

- Added experimental CVC5 support as an SMT solver backend for the OOPSLA19 encoding.

### Bug fixes

- Fixed a `ClassCastException` / `AssertionError` crash during `--temporal` checking when `Next` contains an `IF` or `CASE` whose branches return sets or functions and whose body contains a nested `\/` or `/\` of three or more terms, see #2107.

</details>

### Composition (this repo)
- Bumped to `0.58.0` (from `0.57.0`) via Renovate (#42).

<!-- renovate-pr-40 -->
## [0.58.0] — 2026-06-04
**Digest:** _published on merge — see GitHub Release `gide-apalache-0.58.0`._

### Composition (this repo)
- Base image (temurin JRE) digest refresh via Renovate (#40), on top of 0.58.0 — no upstream version change. See PR #40.


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
