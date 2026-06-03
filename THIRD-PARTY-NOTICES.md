# Third-Party Notices

The container images published from this repository redistribute the following
third-party software, each under its own license. This repository's own build
scripts and workflows are covered by [LICENSE](./LICENSE); the notices below
apply to the **contents of the published images**.

> NOTE(migration): verify each version/license string against the pinned
> values in the corresponding Dockerfile before first public publish, and keep
> them in sync as Renovate bumps the pins.

## Lean4 toolchain image (`gide-lean4-base`)

| Component | Version (pinned in `tools/lean4-base.Dockerfile`) | License | Upstream |
|---|---|---|---|
| Lean 4 | `v4.30.0` | Apache-2.0 | https://github.com/leanprover/lean4 |
| Mathlib4 | `v4.30.0` | Apache-2.0 | https://github.com/leanprover-community/mathlib4 |
| elan | (pinned) | Apache-2.0 / MIT | https://github.com/leanprover/elan |
| Ubuntu base | `ubuntu:26.04` | various (Ubuntu main) | https://ubuntu.com |

## Isabelle toolchain image (`gide-isabelle-base`, `gide-isabelle-source`, `gide-afp-source`)

| Component | Version | License | Upstream |
|---|---|---|---|
| Isabelle | `2025-2` | BSD-style (Isabelle license) | https://isabelle.in.tum.de |
| Archive of Formal Proofs (AFP) | `afp-2026-06-01` | per-entry (BSD / LGPL / etc.) | https://www.isa-afp.org |
| Complex_Bounded_Operators (AFP entry) | (AFP snapshot) | per-AFP-entry | https://www.isa-afp.org/entries/Complex_Bounded_Operators.html |
| Ubuntu base | `ubuntu:26.04` | various | https://ubuntu.com |

## SMT / model-checking solver images

| Image | Solver | License | Upstream |
|---|---|---|---|
| `gide-z3` | Z3 | MIT | https://github.com/Z3Prover/z3 |
| `gide-cvc5` | cvc5 | BSD-3-Clause | https://github.com/cvc5/cvc5 |
| `gide-yices2` | Yices 2 | GPL-3.0 | https://github.com/SRI-CSL/yices2 |
| `gide-dreal` | dReal | Apache-2.0 | https://github.com/dreal/dreal4 |
| `gide-apalache` | Apalache | Apache-2.0 | https://github.com/apalache-mc/apalache |

> NOTE(migration): Yices 2 is GPL-3.0 — redistributing it inside a public image
> is permitted, but confirm there is no objection to shipping a GPL component
> in this image set, and that it stays in its own image (it does) rather than
> linked into anything proprietary.
