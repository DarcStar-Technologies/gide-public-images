# Changelog — `gide-isabelle-base`

Publish history for `ghcr.io/darcstar-technologies/gide-isabelle-base` (thin
Ubuntu runtime + Isabelle distribution + AFP source + pre-baked heaps;
**amd64-only** — the bundled PolyML SIGILLs on arm64, see
[#23](https://github.com/DarcStar-Technologies/gide-public-images/issues/23)).
The verbatim source mirrors `gide-isabelle-source` / `gide-afp-source` move with
this image and are noted per entry. Format and conventions: see the
[root CHANGELOG](../CHANGELOG.md). Licenses:
[THIRD-PARTY-NOTICES](../THIRD-PARTY-NOTICES.md).

## [Isabelle2025-2-afp-2026-06-01] — 2026-06-03
**Digest:** `sha256:de775b26b79a8e3761470e7665f5679f47dc0edcd439d3cf81fe46517cd0351b`

### Upstream
- Isabelle `2025-2` — [home / `NEWS`](https://isabelle.in.tum.de/) (BSD-style)
- Archive of Formal Proofs `afp-2026-06-01` — [isa-afp.org](https://www.isa-afp.org/)
  (per-entry licenses; dated snapshot whose `etc/version` is `2025-2`, matching Isabelle)

### Composition (this repo)
- Thin, CVE-patched Ubuntu `26.04` runtime with the Isabelle install + AFP source
  + the pre-baked session heaps `COPY`ed from a separate heap-builder stage (so a
  weekly Ubuntu CVE bump rebuilds only the thin runtime, not the 90–150 min bake).
- **Pre-baked heaps:** `Complex_Bounded_Operators` (CBO; migration baseline) **and
  `Ordinary_Differential_Equations`** (ODE — added in
  [#28](https://github.com/DarcStar-Technologies/gide-public-images/pull/28),
  gpi[#17](https://github.com/DarcStar-Technologies/gide-public-images/issues/17),
  for AFP `Gronwall`). ODE pulls `HOL-Decision_Procs`, `Triangle`, `List-Index`,
  `Affine_Arithmetic` over the shared `HOL-Analysis`; the numerics/`Lorenz_*`
  sessions are deliberately excluded. Image-size delta from the ODE add: **+23 MB**
  compressed (heaps stored incrementally over `HOL-Analysis`); cold bake ~45 min.
  _This digest re-points the version tag from the prior CBO-only build (same
  upstream version) — a composition change, not an upstream bump._
- AFP bumped to `afp-2026-06-01` in
  [#16](https://github.com/DarcStar-Technologies/gide-public-images/pull/16).

### Provenance
- git `b16cc30` · SLSA provenance + SPDX SBOM attached at publish
- `docker pull ghcr.io/darcstar-technologies/gide-isabelle-base@sha256:de775b26b79a8e3761470e7665f5679f47dc0edcd439d3cf81fe46517cd0351b`

### Source mirrors (verbatim upstream tarballs, `FROM scratch`)
- `gide-isabelle-source:Isabelle2025-2-amd64` — `sha256:53ef9e6a53c0f61b4b1bf9c36649ab90fad93c9af5214f5625978e2b757419ec`
- `gide-isabelle-source:Isabelle2025-2-arm64` — `sha256:15c0c46b06cb1ea0faed69ec9b80ddb299882dc4da1078386314994f40098bd0`
- `gide-afp-source:afp-2026-06-01` — `sha256:08db46d1c417b4457eb271928c4ad4a227a75661638c74d13c8a68fb23ae8bf9`
