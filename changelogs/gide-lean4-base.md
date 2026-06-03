# Changelog — `gide-lean4-base`

Publish history for `ghcr.io/darcstar-technologies/gide-lean4-base` (Ubuntu +
elan + Lean4 toolchain + pre-compiled Mathlib4; **amd64 + arm64**). Format and
conventions: see the [root CHANGELOG](../CHANGELOG.md). The image version _is_
the upstream version; pin by digest for byte-exact reproducibility. Licenses:
[THIRD-PARTY-NOTICES](../THIRD-PARTY-NOTICES.md).

## [v4.30.0] — 2026-06-03
**Digest:** `sha256:88839c6b59be60db44051ec07a1f667e3741116f6f6df6545d6b504c5f2f75f2`

### Upstream
- Lean 4 `v4.30.0` — [release notes](https://github.com/leanprover/lean4/releases/tag/v4.30.0) (Apache-2.0)
- Mathlib4 `v4.30.0` — [release](https://github.com/leanprover-community/mathlib4/releases/tag/v4.30.0) (Apache-2.0; tracks the Lean toolchain)

### Composition (this repo)
- Ubuntu `26.04` base + elan + the pinned Lean4 toolchain, then **Mathlib4
  pre-compiled at build time** (`lake build`) so consumer/proof invocations hit
  the cache instead of a ~30–60 min bake. `ENTRYPOINT ["lake", "env", "lean"]`.
- Native multi-arch: built per-arch (amd64 + arm64) and merged into one manifest
  (no QEMU); both Lean4 and Mathlib publish native aarch64 artifacts.
- Initial published build in this repo (migration baseline). Bumped to v4.30.0
  in [#26](https://github.com/DarcStar-Technologies/gide-public-images/pull/26).

### Provenance
- git `9ca1eb4` · SLSA provenance + SPDX SBOM attached at publish
- `docker pull ghcr.io/darcstar-technologies/gide-lean4-base@sha256:88839c6b59be60db44051ec07a1f667e3741116f6f6df6545d6b504c5f2f75f2`
