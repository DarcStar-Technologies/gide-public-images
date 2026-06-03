# Migration Notes — staging tree for `gide-public-images`

This directory (`migration/gide-prover-toolchain/`) is a **drop-in staging tree**
for the new public repo. It is NOT wired into the private repo's CI — it lives
here only so the adapted files can be reviewed in one PR before the public repo
is created. See `docs/plans/public-base-image-migration.md` for the full plan.

To create the public repo: copy the contents of this directory to the root of a
fresh `darcstar-technologies/gide-public-images` repository.

## Tree

```
.github/workflows/
  build-lean4-base-image.yml       # ADAPTED: base-only + Mathlib smoke (was base+overlay+proof-verify)
  build-isabelle-base-image.yml    # ADAPTED: base-only + AFP-heap smoke (was base+overlay+proof-verify)
  build-prover-images.yml          # VERBATIM + banner (already public-safe, GH-hosted)
  mirror-isabelle-distribution.yml # VERBATIM + banner (must stay GH-hosted: TUM/AFP egress)
  scan-published-images.yml        # NEW: scoped to the 7 toolchain images built here
  prune-old-image-tags.yml         # NEW: scoped to the 7 sha-tagged toolchain packages
tools/
  lean4-base.Dockerfile            # VERBATIM (toolchain-only)
  isabelle-base.Dockerfile         # VERBATIM (toolchain-only)
  z3 / cvc5 / yices2 / dreal / apalache .Dockerfile  # VERBATIM
README.md  SETUP.md  CLAUDE.md  renovate.json  THIRD-PARTY-NOTICES.md  LICENSE  MIGRATION-NOTES.md
```

## What changed vs the private-repo sources

| File | Change |
|---|---|
| `build-lean4-base-image.yml` | Removed overlay (`gide-lean4`) build/merge/promote jobs and the proof-consuming `verify` job (`check_proofs.py --lean-only`). Replaced verify with a Mathlib-only Lean smoke. Flipped `blacksmith-*` runners → GitHub-hosted. See the workflow's own `# TODO(migration):` markers for the exact lean/lake invocation to confirm. |
| `build-isabelle-base-image.yml` | Removed overlay (`gide-isabelle`) jobs and the daemon/`check_proofs.py --isabelle-only` verify path. Replaced verify with an AFP-heap-load smoke theory. Flipped runners → GitHub-hosted (RAM/time caveat flagged inline). |
| `build-prover-images.yml`, `mirror-isabelle-distribution.yml` | Verbatim; added a migration banner comment. Already GitHub-hosted. |
| `scan-published-images.yml` | New matrix = 7 toolchain images only (dropped `gide-ci-base`, `gide-lean4`, `gide-isabelle` — those scan from the private repo). |
| `prune-old-image-tags.yml` | New matrix = 7 sha-tagged toolchain packages (dropped the private leaves; mirrors omitted — different tag scheme). |
| `renovate.json` | customManagers ported verbatim from the private repo — they match the `ARG …_VERSION=` lines directly (no annotation needed), with the correct `extractVersion` per tool. Covers Lean4/Mathlib + the 5 SMT solvers; Isabelle/AFP have no upstream datasource (manual bump). See SETUP.md §5. |

## Manual steps that CANNOT be scripted here (do these at cutover)

1. **Create the public repo** and copy this tree to its root.
2. **Choose & add a LICENSE** (placeholder present) — see `LICENSE`.
3. **GHCR package settings** (per the 7 moved packages + 2 mirror packages):
   - Visibility → **Public** (needs IP sign-off; boundary audit confirms toolchain-only).
   - Link the public repo with **Write**; keep the private `gide` repo at Read.
4. **First-publish bootstrap:** dispatch each build workflow and confirm images
   land at the unchanged `ghcr.io/darcstar-technologies/gide-*` refs and that
   `docker buildx imagetools inspect <ref>:latest` succeeds **without auth**.
5. **Confirm runner capacity:** the Isabelle base CBO + ODE heap build
   (~90–150 min for the CBO chain plus the Ordinary_Differential_Equations
   delta; ~6 GB peak RAM at `-j 1`) must fit GitHub's standard public runner;
   if not, opt into a larger runner (billed even on public repos) — see the
   workflow's TODO.

## Changes required in the PRIVATE `gide` repo (separate PR, step 6 of the plan)

These are NOT in this staging tree — they are deletions/edits in `gide`:

1. **Delete** the now-migrated build workflows: `build-lean4-base-image.yml`,
   `build-isabelle-base-image.yml`, `build-prover-images.yml`,
   `mirror-isabelle-distribution.yml`, and the migrated `tools/*.Dockerfile`
   base/solver files (keep `tools/lean4.Dockerfile` / `tools/isabelle.Dockerfile`
   overlays).
2. **Overlay workflows** (`build-lean4-image.yml`, `build-isabelle-image.yml`):
   resolve the inline-base-build fallback (plan §2.2) — drop it and rely on the
   published public base with a loud bootstrap error, OR vendor a synced copy.
   The `FROM ${BASE_IMAGE}` default already points at the public ref; pulling a
   public base needs no login (keep login only for the private push).
3. **`scan-published-images.yml` / `prune-old-image-tags.yml`**: shrink their
   matrices to the 3 private packages (`gide-ci-base`, `gide-lean4`,
   `gide-isabelle`).
4. **`renovate.json`**: remove the entries for the migrated Dockerfiles so the
   two repos don't both manage them.
5. **Docs:** update `docs/formal-verification-pipeline.md` (image provenance now
   external), `proofs/README.md`, and `CLAUDE.md` external-deps note; leave a
   tombstone pointing at the public repo.

Keep step-6 deletions in their own revertible commit (rollback = restore from
git history + re-link packages).

## Not in scope (per plan §7)

`gide-ci-base` stays private (coupled to `.zig-version`/`pyproject.toml`); the
proof-verify sweeps stay private; `proofs/` does not move.
