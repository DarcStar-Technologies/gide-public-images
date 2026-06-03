# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Guidance for Claude Code working in **`darcstar-technologies/gide-public-images`** —
the public repository that builds the third-party prover **toolchain images** for
the GIDE formal-verification pipeline. This is a navigation file; the
operational detail lives in the docs it points to.

## The one rule that defines this repo

**This repo contains ONLY upstream, open-source toolchain. It must never contain
GIDE intellectual property** — no proof files, no theorem catalog, no `src/`, no
`proofs/`, no design docs. The images here ship Lean4 + Mathlib4, Isabelle + AFP,
and a few SMT/model-checking solvers; nothing GIDE-specific.

This is not a style preference — it is the security boundary that justifies the
repo being public (Actions are free on public repos). The theorem-baking overlay
images (`gide-lean4`, `gide-isabelle`) and all proof verification live in the
**private** `darcstar-technologies/gide` repo.

**If a change here would require adding any proof/catalog/`src` content, stop —
it belongs in the private repo, not here.**

## What this repo publishes

All images publish to the org-scoped namespace `ghcr.io/darcstar-technologies/<image>`
and are **public** (anonymous `docker pull` works). The ref is org-scoped, not
repo-scoped, so the private repo consumes these unchanged.

| Image | Contents | Workflow | Arch |
|---|---|---|---|
| `gide-lean4-base` | Ubuntu + elan + Lean4 + pre-compiled Mathlib4 | `build-lean4-base-image.yml` | amd64 + arm64 |
| `gide-isabelle-base` | Ubuntu + Isabelle + AFP + pre-baked CBO heap | `build-isabelle-base-image.yml` | amd64-only |
| `gide-isabelle-source` / `gide-afp-source` | Verbatim upstream tarballs | `mirror-isabelle-distribution.yml` | n/a (`FROM scratch`) |
| `gide-z3` / `gide-cvc5` / `gide-yices2` / `gide-dreal` / `gide-apalache` | SMT / model-checking solver binaries | `build-prover-images.yml` | see workflow |

## Finding things

| Looking for | Go to |
|---|---|
| What each image is + how the private repo consumes it | [`README.md`](README.md) |
| First-time bootstrap (repo settings, GHCR visibility, publish order) | [`SETUP.md`](SETUP.md) |
| Upstream licenses shipped in the images | [`THIRD-PARTY-NOTICES.md`](THIRD-PARTY-NOTICES.md) |
| Why this repo exists + what changed vs the private originals | [`MIGRATION-NOTES.md`](MIGRATION-NOTES.md) |
| Dependency-update config | [`renovate.json`](renovate.json) |
| Dockerfiles | [`tools/`](tools/) |
| CI workflows | [`.github/workflows/`](.github/workflows/) |

## Build & test

There is no `just`/Zig/Python build here — it is a Docker-image repo.

```bash
# Build a base image locally (per-arch; the CBO/Mathlib bakes are slow):
docker buildx build -f tools/lean4-base.Dockerfile --platform linux/amd64 .
docker buildx build -f tools/isabelle-base.Dockerfile --platform linux/amd64 .

# CI: each build-*.yml runs on push to its Dockerfile, a weekly cron, and
# workflow_dispatch. Trigger a publish manually:
gh workflow run build-lean4-base-image.yml
```

CI uses the **verify-then-promote** pattern: build a `:candidate-<sha>`, run a
**toolchain smoke** inside it (does Mathlib resolve / does the CBO heap load),
then promote to `:latest` + `:<sha>` only on smoke-green.

## Conventions (don't break these)

- **The smoke is a toolchain check ONLY.** It deliberately does not verify the
  GIDE proof catalog (which isn't here). The proof gate happens at *adoption*
  time in the private repo (the overlay pins these bases by digest; a Renovate
  digest bump runs `ci-formal-theorems` before adopting). So `:latest` here is
  "toolchain-good," not "proof-verified." Do not try to add proof verification.
- **Registry-backed buildkit cache, not `type=gha`.** The Mathlib (~14 GB) and
  Isabelle/CBO (~12 GB) layers exceed GitHub Actions' 10 GB/repo cache cap, so
  the base builds use `type=registry,ref=…:buildcache-<arch>`. Keep it that way.
- **CI runs on free standard runners — keep it that way.** Every `runs-on:` is
  `ubuntu-24.04` (amd64) or `ubuntu-24.04-arm` (arm64) — standard GitHub-hosted
  runners, which are free with unlimited minutes on public repos (this is part
  of why the repo is public). The Mathlib/CBO cold bakes fit the standard runner
  (4 vCPU / ~16 GB) within the 6h job cap. **Larger runners (`*-cores`/xlarge),
  self-hosted, and macOS/Windows runners are billed *even on public repos*** —
  don't introduce them (the private `gide` repo's billed `ARM 4-core` line is the
  cautionary example). Runner-sizing `# TODO(migration):` notes are about
  confirming the standard runner suffices, not licence to switch to a billed one.
- **`isabelle-base` is amd64-only** (bundled PolyML SIGILLs on ARM). Don't add
  `linux/arm64` to it without rebuilding PolyML from source.
- **Action pins** use the repo-canonical `docker/build-push-action@…# v7` SHA;
  keep all build steps on the same pin.
- **Isabelle/AFP version bumps are manual** (no Renovate datasource) but
  **PR-driven**: edit the `ISABELLE_VERSION` / `AFP_DATED_TAG` / `AFP_SHA256` /
  `AFP_DIRNAME` ARGs in `tools/isabelle-base.Dockerfile` in one PR. Merging it
  re-runs the mirror (it triggers on a push touching that Dockerfile) to publish
  the matching source tags, then rebuilds the base via `workflow_run` — no manual
  mirror dispatch. Verify the AFP tarball's `etc/version` matches the Isabelle
  version before bumping (the dated tag alone is not a reliable pairing signal).
  Lean4/Mathlib + the 5 SMT solvers are auto-tracked by `renovate.json`.
- **GHCR package visibility is a manual, one-time flip** per package and cannot
  be set by CI — see `SETUP.md`.
- Look for `# TODO(migration):` markers — they flag the few things that can only
  be confirmed against the real published images (smoke invocations, runner RAM).
