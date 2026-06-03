# Changelog

Publish history for the images built by this repository. Because each image is
a thin repackaging of an **upstream** project, the history is split **per
image** under [`changelogs/`](./changelogs/) — the images version on
independent cadences (Lean4/Mathlib together, Isabelle/AFP together, each solver
separately), so one interleaved log would be noise.

| Image | Changelog |
|---|---|
| `gide-lean4-base` | [changelogs/gide-lean4-base.md](./changelogs/gide-lean4-base.md) |
| `gide-isabelle-base` (+ `gide-isabelle-source` / `gide-afp-source`) | [changelogs/gide-isabelle-base.md](./changelogs/gide-isabelle-base.md) |
| `gide-z3` | [changelogs/gide-z3.md](./changelogs/gide-z3.md) |
| `gide-cvc5` | [changelogs/gide-cvc5.md](./changelogs/gide-cvc5.md) |
| `gide-yices2` | [changelogs/gide-yices2.md](./changelogs/gide-yices2.md) |
| `gide-dreal` | [changelogs/gide-dreal.md](./changelogs/gide-dreal.md) |
| `gide-apalache` | [changelogs/gide-apalache.md](./changelogs/gide-apalache.md) |

## Conventions

Each per-image file follows [Keep a Changelog](https://keepachangelog.com/),
adapted for a "we repackage upstream" repo:

- **The image version _is_ the upstream version.** This repo does not invent its
  own SemVer — the version tag mirrors the upstream release string (see
  [#19](https://github.com/DarcStar-Technologies/gide-public-images/issues/19)):
  SemVer where upstream is (`gide-z3:4.16.0`, `gide-lean4-base:v4.30.0`), the
  upstream string otherwise (`gide-isabelle-base:Isabelle2025-2-afp-2026-06-01`).
- **Each entry is a _publish event_.** A new entry is added whenever the
  published image changes — an upstream bump, a composition change (bake
  recipe), **or** a same-version CVE-refresh rebuild (which re-points a version
  tag to a new digest with the same upstream version). The latter use a
  `Security` note so every digest move is explained.
- **Entry shape:**

  ```markdown
  ## [<upstream-version>] — <date>
  **Digest:** `sha256:<full>`

  ### Upstream
  - <Component> `<version>` — [release notes](<url>)

  ### Composition (this repo)
  - <bake recipe / pre-baked artifacts / base-OS digest / scanner / tagging>

  ### Provenance
  - git `<sha>` · SLSA provenance + SPDX SBOM attached at publish
  ```

## Pinning & verification

- Tags: `:latest` (rolling), `:<upstream-version>` (human/matrix pin),
  `:<git-sha>` (forensic) — all the same digest.
- A version tag tracks the **latest build** of that upstream version (a CVE
  rebuild re-points it). For byte-exact reproducibility, **pin by digest**
  (`…@sha256:…`, recorded in each entry).
- Every build attaches **SLSA provenance + an SPDX SBOM**; `scan-published-images.yml`
  runs a scheduled Trivy CVE sweep. See [`README.md`](./README.md#provenance--security).

## Keeping it current

A CI gate (`.github/workflows/require-changelog.yml`) fails any PR that changes a
published image's `tools/<image>.Dockerfile` without updating the matching
`changelogs/<image>.md` — so a version bump (including Renovate's) adds its
changelog entry in the same PR. For a change that does **not** affect a published
image (comment-only edits, CI-only changes), apply the **`skip-changelog`** label
to bypass the gate. Auto-stamping entries at promote time (Phase 2) is tracked in
[#29](https://github.com/DarcStar-Technologies/gide-public-images/issues/29).

## Status

This is the **initial backfill** (seeded 2026-06-03 from the then-current
published digests). History prior to the seed lives in git / PR refs.
Automating changelog entries on publish (a CI gate on bump PRs, then
promote-job stamping / drafted GitHub Releases) and adding OCI
`image.version`/`revision`/`created`/`documentation` annotations are tracked in
[#29](https://github.com/DarcStar-Technologies/gide-public-images/issues/29).
This changelog is **toolchain-only** — it records upstream versions and our
composition, never GIDE proof/catalog content.
