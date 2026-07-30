# Changelog — `gide-lean4-base`

Publish history for `ghcr.io/darcstar-technologies/gide-lean4-base` (Ubuntu +
elan + Lean4 toolchain + pre-compiled Mathlib4; **amd64 + arm64**). Format and
conventions: see the [root CHANGELOG](../CHANGELOG.md). The image version _is_
the upstream version; pin by digest for byte-exact reproducibility. Licenses:
[THIRD-PARTY-NOTICES](../THIRD-PARTY-NOTICES.md).

<!-- renovate-pr-71 -->
## [v4.32.2] — 2026-07-30
**Digest:** _published on merge — see GitHub Release `gide-lean4-base-v4.32.2`._

### Upstream
- Mathlib4 `v4.32.2` — [release notes](https://github.com/leanprover-community/mathlib4/releases/tag/v4.32.2)

<details><summary>Upstream release notes (captured from PR #71)</summary>

### [`v4.32.2`](https://redirect.github.com/leanprover-community/mathlib4/compare/v4.32.1...v4.32.2)

[Compare Source](https://redirect.github.com/leanprover-community/mathlib4/compare/v4.32.1...v4.32.2)

### [`v4.32.1`](https://redirect.github.com/leanprover-community/mathlib4/compare/v4.32.0...v4.32.1)

[Compare Source](https://redirect.github.com/leanprover-community/mathlib4/compare/v4.32.0...v4.32.1)

### [`v4.32.0`](https://redirect.github.com/leanprover-community/mathlib4/compare/v4.31.0...v4.32.0)

[Compare Source](https://redirect.github.com/leanprover-community/mathlib4/compare/v4.31.0...v4.32.0)

### [`v4.31.0`](https://redirect.github.com/leanprover-community/mathlib4/compare/v4.30.0...v4.31.0)

[Compare Source](https://redirect.github.com/leanprover-community/mathlib4/compare/v4.30.0...v4.31.0)



### [`v4.32.2`](https://redirect.github.com/leanprover/lean4/releases/tag/v4.32.2)

[Compare Source](https://redirect.github.com/leanprover/lean4/compare/v4.32.1...v4.32.2)

This is the v4.32.2 release of Lean. View the [release notes](https://lean-lang.org/doc/reference/latest/releases/v4.32.2/) for more information.

### [`v4.32.1`](https://redirect.github.com/leanprover/lean4/releases/tag/v4.32.1)

[Compare Source](https://redirect.github.com/leanprover/lean4/compare/v4.32.0...v4.32.1)

This is the v4.32.1 release of Lean. View the [release notes](https://lean-lang.org/doc/reference/latest/releases/v4.32.1/) for more information.

### [`v4.32.0`](https://redirect.github.com/leanprover/lean4/releases/tag/v4.32.0)

[Compare Source](https://redirect.github.com/leanprover/lean4/compare/v4.31.0...v4.32.0)

This is the v4.32.0 release of Lean. View the [release notes](https://lean-lang.org/doc/reference/latest/releases/v4.32.0/) for more information.

### [`v4.31.0`](https://redirect.github.com/leanprover/lean4/releases/tag/v4.31.0)

[Compare Source](https://redirect.github.com/leanprover/lean4/compare/v4.30.0...v4.31.0)

This is the v4.31.0 release of Lean. View the [release notes](https://lean-lang.org/doc/reference/latest/releases/v4.31.0/) for more information.

</details>

### Composition (this repo)
- Bumped to `v4.32.2` (from `v4.30.0`) via Renovate (#71).


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
