# gide-public-images

Reproducible, public Docker images of the **third-party prover toolchain** used
by GIDE's formal-verification pipeline. These images carry **only upstream
open-source software** — Lean4 + Mathlib4, Isabelle + AFP, and a handful of
SMT / model-checking solvers. They contain **no GIDE proof content, no theorem
catalog, and no source** from the private GIDE repository.

They are built here (a public repo) so their CI runs on GitHub's free,
unlimited public runners. The theorem-baking overlay images and all proof
verification live in the private `DarcStar-Technologies/gide` repository.

> **First-time setup:** see [SETUP.md](./SETUP.md) for the bootstrap runbook
> (repo settings, GHCR package visibility, dependency-ordered first publish).

## Published images

All images publish to the org-scoped GHCR namespace
`ghcr.io/darcstar-technologies/<image>` and are **public** (anonymous `docker
pull` works):

| Image | Contents | Build workflow |
|---|---|---|
| `gide-lean4-base` | Ubuntu + elan + Lean4 + pre-compiled Mathlib4 | `build-lean4-base-image.yml` |
| `gide-isabelle-base` | Ubuntu + Isabelle + AFP + pre-baked Complex_Bounded_Operators + Ordinary_Differential_Equations heaps | `build-isabelle-base-image.yml` |
| `gide-isabelle-source` | Verbatim upstream Isabelle distribution tarball | `mirror-isabelle-distribution.yml` |
| `gide-afp-source` | Verbatim upstream AFP tarball | `mirror-isabelle-distribution.yml` |
| `gide-z3` / `gide-cvc5` / `gide-yices2` / `gide-dreal` / `gide-apalache` | SMT / model-checking solver binaries | `build-prover-images.yml` |

## How the private repo consumes these

GHCR packages are namespaced by **org**, not by repo, so the pull refs are
identical regardless of which repo builds them. The private GIDE overlay
Dockerfiles simply `FROM ghcr.io/darcstar-technologies/gide-lean4-base:latest`
(and the Isabelle equivalent) and layer the GIDE proof tree on top. No pull
credentials are needed for these public bases.

```
gide-lean4-base  ──FROM──►  gide-lean4   (private; bakes proofs/)
gide-isabelle-base ─FROM─►  gide-isabelle (private; bakes proofs/)
```

## Image tags

Every image carries three kinds of tag (all the same digest):

- **`:latest`** — rolling; the most recent good build.
- **`:<upstream-version>`** — human-readable, for pinning and version matrices.
  Semver where upstream is (`gide-z3:4.16.0`, `gide-lean4-base:v4.30.0`); the
  upstream version string otherwise (`gide-isabelle-base:Isabelle2025-2-afp-2026-06-01`,
  `gide-dreal:4.21.06.2`). Derived from the Dockerfile version `ARG`, so a
  Renovate bump moves it automatically.
- **`:<git-sha>`** — forensic; the exact commit that built the image.

The source mirrors are tagged by upstream version directly
(`gide-isabelle-source:Isabelle2025-2-<arch>`, `gide-afp-source:afp-2026-06-01`).

A version tag tracks the *latest build* of that upstream version (a CVE rebuild
re-points it); for byte-exact reproducibility, pin by digest (`@sha256:…`).

## Changelog

Per-image publish history — upstream versions (with links to each project's own
release notes), the changes this repo makes during composition, and the
published digests — lives in [`CHANGELOG.md`](./CHANGELOG.md) (one file per image
under [`changelogs/`](./changelogs/)). Each entry is a publish event; pin by
digest for byte-exact reproducibility.

## Provenance & security

- Each build attaches SLSA provenance + an SPDX SBOM at publish time.
- Each image carries OCI annotations — `image.source` + `image.description`
  (config labels) plus `image.version`, `image.revision`, `image.created`, and
  `image.documentation` (a link to the image's [changelog](./CHANGELOG.md)) —
  so `docker buildx imagetools inspect` surfaces the version, build provenance,
  and where to read the notes.
- `scan-published-images.yml` runs a scheduled Trivy CVE sweep, uploading SARIF
  to this repo's Security tab.
- `prune-old-image-tags.yml` garbage-collects stale per-commit / candidate tags.
- Upstream version drift (Mathlib4, Isabelle, AFP, solver versions) and base
  image digests are tracked by Renovate (`renovate.json`).

## License

This repository's build scripts are licensed under [LICENSE](./LICENSE). The
**images** redistribute third-party software under their own licenses — see
[THIRD-PARTY-NOTICES.md](./THIRD-PARTY-NOTICES.md).
