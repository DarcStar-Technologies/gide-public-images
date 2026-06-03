# SETUP — standing up this repo

Operator runbook for bootstrapping `darcstar-technologies/gide-public-images`
the first time. This repo builds the **public, IP-free** prover toolchain images
consumed by the private GIDE formal-verification pipeline. See `README.md` for
what each image is and `MIGRATION-NOTES.md` for the broader migration context.

Assumes the `gh` CLI authenticated to the `darcstar-technologies` org with
`admin:org` + `write:packages` scopes.

> ## ✅ Bootstrap COMPLETE — 2026-06-02
>
> All 9 packages are published, smoke-promoted to `:latest`, and **public** —
> anonymous (credential-free) `docker pull` was verified for every package and
> the per-arch platforms match the build matrix (`gide-isabelle-base`,
> `gide-yices2`, `gide-dreal` are amd64-only by design; the rest are
> amd64+arm64). Every image carries OCI `image.source`/`description` labels.
>
> The steps below are retained as the operator runbook for re-bootstrapping or
> onboarding a new maintainer; per-step status is marked inline. Code scanning
> is enabled (CodeQL default setup for `actions`) and `scan-published-images.yml`
> was verified uploading Trivy SARIF for all 7 toolchain images to the Security
> tab — no items remain open.

## 1. Repository settings (Settings →)

> **Status:** ✅ all done — branch protection on `main`, LICENSE (MIT),
> Actions/fork settings, and **code scanning** (CodeQL default setup for
> `actions`). `scan-published-images.yml` was verified uploading Trivy SARIF for
> all 7 toolchain images to the Security tab (no `upload-sarif` 403).

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

> **Status:** ✅ all 9 packages flipped to **Public** and anonymously pullable.

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

> **Status:** ✅ first publish done in this order; all builds smoke-green and
> promoted to `:latest`.

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

> **Status:** ✅ verified 2026-06-02 — all 9 packages return a `200` on an
> anonymous manifest pull (including the two `FROM scratch` source mirrors,
> which the loop below omits because they carry versioned tags, not `:latest`).
> Where no Docker/buildx daemon is available, the equivalent check is an
> anonymous registry-API pull: grab a token from
> `https://ghcr.io/token?service=ghcr.io&scope=repository:darcstar-technologies/<img>:pull`,
> then `GET https://ghcr.io/v2/darcstar-technologies/<img>/manifests/<tag>` with
> that bearer token — a `200` proves credential-free pullability.

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

> **Status:** ✅ **active** (since 2026-06-03). `renovate.json` is committed and
> working; Renovate is watching this repo — **Dependency Dashboard: #21** — and
> runs on schedule (before 6am Monday UTC). Verified detecting real updates
> (e.g. an apalache version bump + the GitHub Actions / ubuntu / temurin digest
> pins) and honoring the isabelle-base dockerfile-manager disable.

**How it was activated (for re-bootstrap):** the org Renovate app
(`DarcStar-Technologies`) runs in **"selected repositories"** mode, so the repo
had to be granted access — **Org Settings → GitHub Apps → Renovate → Configure →
Repository access** → add `gide-public-images`. This is an **org-owner UI action**
(the `PUT /user/installations/{id}/repositories/{id}` API is owner-gated and 403s
for a non-owner token; CI can't do it). Because `renovate.json` already existed,
Renovate **skipped the onboarding PR** and went straight to the Dependency
Dashboard + scheduled PRs.

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
**in one PR** by editing the `ISABELLE_VERSION` / `AFP_DATED_TAG` / `AFP_SHA256`
/ `AFP_DIRNAME` ARGs in `tools/isabelle-base.Dockerfile`. On merge, the mirror
re-runs from the new in-tree pins (it triggers on a push touching that
Dockerfile) and publishes the matching source tags, then `build-isabelle-base`
rebuilds via `workflow_run` — no manual mirror dispatch, no two-step ordering.
Verify the new AFP tarball targets the pinned Isabelle first:

```bash
curl -sL https://isa-afp.org/release/<afp-dated-tag>.tar.gz \
  | tar xzO --wildcards '*/etc/version' | grep '^VERSION='   # must match ISABELLE_VERSION
```

See the bump-order note in `build-isabelle-base-image.yml`.

## 6. Hand-off to the private repo

> **Status:** 🔜 unblocked — step 4 is green, so the private cleanup PR may now
> proceed. This is the next action, owned by the private `gide` repo.

Only after step 4 is green: the private `gide` repo applies its gated cleanup
PR (delete the migrated builds, rewire the overlays to `FROM` these published
bases). That PR is staged in the private repo at
`migration/private-repo-cleanup/` and must NOT merge until these images are
live and anonymously pullable.
