# SETUP — standing up this repo

Operator runbook for bootstrapping `darcstar-technologies/gide-public-images`
the first time. This repo builds the **public, IP-free** prover toolchain images
consumed by the private GIDE formal-verification pipeline. See `README.md` for
what each image is and `MIGRATION-NOTES.md` for the broader migration context.

Assumes the `gh` CLI authenticated to the `darcstar-technologies` org with
`admin:org` + `write:packages` scopes.

## 1. Repository settings (Settings →)

- **Actions → General → Workflow permissions:** the default (read-only) is fine
  — every workflow declares its own `permissions:` block (incl. `packages:
  write`), which overrides the repo default for the push.
- **Actions → General → Fork pull request workflows:** "Require approval for all
  outside collaborators" (public repo — keep fork PRs from running the
  push-capable workflows without a maintainer click).
- **Code security → Code scanning: enable.** `scan-published-images.yml` uploads
  Trivy SARIF via `upload-sarif`; this 403s without code scanning enabled (free
  on public repos).
- **Branch protection on `main`:** require PR review + status checks; restrict
  direct pushes.
- **LICENSE:** replace the placeholder `LICENSE` with the chosen license text
  before first publish (recommend Apache-2.0 or MIT — build infra, no GIDE IP).

## 2. GHCR packages — visibility + access

These 9 packages publish to the org-scoped namespace
`ghcr.io/darcstar-technologies/<image>`:

```
gide-lean4-base  gide-isabelle-base  gide-isabelle-source  gide-afp-source
gide-z3  gide-cvc5  gide-yices2  gide-dreal  gide-apalache
```

If they already exist (built previously by the private `gide` repo), re-link
each: **org Packages → <pkg> → Settings →**
- *Manage Actions access* → add this repo (`gide-public-images`) with
  **Write**; keep `gide` at **Read** during the overlap so the private overlays
  can still pull.
- *Danger Zone → Change visibility → **Public***.

If they don't exist yet, the first build below creates them (private by
default) — then flip each to **Public** in the same Danger Zone.

> Visibility is a one-time manual flip per package; CI cannot set it.

## 3. First publish — DEPENDENCY ORDER MATTERS

`build-isabelle-base-image.yml` does `COPY --from=` the two mirror images, so
publish in this order:

```bash
R=darcstar-technologies/gide-public-images
gh workflow run mirror-isabelle-distribution.yml -R "$R"   # → gide-isabelle-source, gide-afp-source
# wait for completion, set those two packages public, then:
gh workflow run build-isabelle-base-image.yml   -R "$R"    # FROM the mirrors
gh workflow run build-lean4-base-image.yml      -R "$R"    # standalone
gh workflow run build-prover-images.yml         -R "$R"    # standalone (5 SMT)
```

Flip each package to Public once it first publishes.

> If a base build's `smoke` job fails on first run, check the
> `# TODO(migration):` smoke-invocation assumptions against the real image —
> the Lean entrypoint/WORKDIR (`build-lean4-base-image.yml`) and the Isabelle
> heap theory name (`build-isabelle-base-image.yml`,
> `Complex_Bounded_Operators.Complex_Bounded_Linear_Function`). These are the
> only steps that couldn't be verified pre-publish.

## 4. Verify (must pass WITHOUT auth once public)

```bash
for img in gide-lean4-base gide-isabelle-base gide-z3 gide-cvc5 \
           gide-yices2 gide-dreal gide-apalache; do
  docker buildx imagetools inspect "ghcr.io/darcstar-technologies/${img}:latest" \
    >/dev/null 2>&1 && echo "OK  ${img}" || echo "FAIL ${img}"
done
```

A `FAIL` here usually means the package is still private (step 2) or the build
hasn't published yet (step 3).

## 5. Renovate

Add this repo to the org Renovate config or install the Renovate GitHub App.
`renovate.json` ships with working customManagers (ported from the private repo)
that track the version `ARG`s directly — no Dockerfile annotations needed:

- **Lean4 toolchain + Mathlib4** (`tools/lean4-base.Dockerfile`) — github-tags;
  Mathlib is gated to the dependency dashboard (tags weekly) to avoid a
  ~30-60 min base rebuild every Monday.
- **Z3 / cvc5 / yices2 / dreal / apalache** (`tools/*.Dockerfile`) —
  github-releases, each with the correct `extractVersion` for its tag format.
- **`FROM ubuntu:26.04`** + GitHub Actions — the native managers + digest pinning.

**Isabelle / AFP are NOT auto-tracked** — there is no upstream Renovate
datasource for them (the private repo has no manager for them either). Bump them
manually by editing `ISABELLE_VERSION` / `AFP_DATED_TAG` in
`tools/isabelle-base.Dockerfile` (or via the workflow_dispatch inputs), after
running the mirror workflow to publish the new source tags — see the bump-order
note in `build-isabelle-base-image.yml`.

## 6. Hand-off to the private repo

Only after step 4 is green: the private `gide` repo applies its gated cleanup
PR (delete the migrated builds, rewire the overlays to `FROM` these published
bases). That PR is staged in the private repo at
`migration/private-repo-cleanup/` and must NOT merge until these images are
live and anonymously pullable.
