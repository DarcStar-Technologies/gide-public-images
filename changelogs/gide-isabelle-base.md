# Changelog — `gide-isabelle-base`

Publish history for `ghcr.io/darcstar-technologies/gide-isabelle-base` (thin
Ubuntu runtime + Isabelle distribution + AFP source + pre-baked heaps;
**amd64-only** — the bundled PolyML SIGILLs on arm64, see
[#23](https://github.com/DarcStar-Technologies/gide-public-images/issues/23)).
The verbatim source mirrors `gide-isabelle-source` / `gide-afp-source` move with
this image and are noted per entry. Format and conventions: see the
[root CHANGELOG](../CHANGELOG.md). Licenses:
[THIRD-PARTY-NOTICES](../THIRD-PARTY-NOTICES.md).

## [Isabelle2025-2-afp-2026-07-21] — 2026-07-30 (unreleased; composition change)
**Digest:** _published on merge — re-points the `Isabelle2025-2-afp-2026-07-21`
version tag to a new digest (same upstream versions)._

### Upstream
- Isabelle `2025-2` and AFP `afp-2026-07-21` — **unchanged** from the entry
  below. This is a composition change only.

### Composition (this repo)
- **AFP is now registered as an Isabelle _component_** (`isabelle components -u
  /opt/afp/thys`) instead of via a hand-written `~/.isabelle/<ver>/ROOTS` line
  ([#68](https://github.com/DarcStar-Technologies/gide-public-images/issues/68)).
  This is the upstream-supported method ("From Isabelle2021-1 on, the recommended
  method … is the `isabelle components -u` command",
  [AFP help](https://www.isa-afp.org/help/)) and it eliminates 13
  `*** Missing session sources entry ".../thys/{Deriving,Containers,Show,Wlog}/*.ML"`
  errors from the CBO bake. Those came from `src/Pure/Build/store.scala` and mean
  an `isabelle_sources` **path-spelling** mismatch (ROOTS named the
  `/opt/afp/thys` symlink; the build recorded the resolved dated path) — the
  `File.symbolic_path` conflation Makarius diagnosed on isabelle-users in 2023,
  whose reported fix was exactly component registration. AFP's own
  `etc/settings` declares `isabelle_directory '$AFP_BASE'` / `'$AFP'`, so paths
  are recorded in one canonical symbolic form.
- Side effect worth knowing: the AFP component compares `$ISABELLE_NAME` against
  the tarball's `etc/version` and warns `### Version mismatch: <isabelle> with
  afp-<ver>`, so the Isabelle/AFP pairing check is now enforced inside every
  build rather than only by hand at bump time.
- **No change to the bake recipe**, the runtime base, the pinned upstream
  versions, or the tagging scheme. Registration lives in the `heap-builder`
  stage, so this is a cold rebuild.

### Provenance
- SLSA provenance + SPDX SBOM attached at publish

### Source mirrors (verbatim upstream tarballs, `FROM scratch`)
- Unchanged — same tags and digests as the entry below.

## [Isabelle2025-2-afp-2026-07-21] — 2026-07-29
**Digest:** `sha256:62089f75103f2aa11ed1227c6f541d691939bfcb7f649958378a54dbef9636ab`

### Upstream
- Isabelle `2025-2` — [home / `NEWS`](https://isabelle.in.tum.de/) (BSD-style)
  — **unchanged**; `Isabelle2025-2` is still the current release, so the
  distribution mirror tags do not move with this entry.
- Archive of Formal Proofs `afp-2026-07-21` — [isa-afp.org](https://www.isa-afp.org/)
  (per-entry licenses; dated snapshot whose `etc/version` reports
  `AFP_VERSION=2025-2`, matching Isabelle2025-2 — verified against the upstream
  tarball before pinning). Supersedes `afp-2026-06-01`; the intervening dated
  snapshots (`afp-2026-07-15`, `afp-2026-07-17`) are skipped in favour of the
  newest snapshot on the same Isabelle line.

### Composition (this repo)
- **AFP-only bump.** `AFP_DATED_TAG` / `AFP_SHA256` / `AFP_DIRNAME` advance to
  `afp-2026-07-21` (tarball 102,780,837 bytes,
  `sha256:544de82b35d1bb6aaa1923f11cdd50d702824a6e0601cd72ee7e43e5eca85d6f`).
  No change to the bake recipe, the runtime base, or the tagging scheme.
- **Pre-baked heaps unchanged:** `Complex_Bounded_Operators` (CBO) +
  `Ordinary_Differential_Equations` (ODE), still one `isabelle build -j 1 -b`
  invocation at `timeout_scale=2.0`; `thys/Complex_Bounded_Operators/ROOT` and
  `thys/Ordinary_Differential_Equations/ROOT` both confirmed present in the new
  snapshot, so both baked sessions keep their names.
- Because the AFP pin feeds the `heap-builder` stage, this was a **cold rebuild**;
  actual bake 54 min (`HOL-Analysis` 26:20, CBO 14:17, ODE 4:13).
- Adoption stays digest-gated downstream: the overlay pins this base by digest
  and runs `ci-formal-theorems` before adopting, which is the gate for the open
  ODE `session_start` regression
  ([#54](https://github.com/DarcStar-Technologies/gide-public-images/issues/54)).

### Provenance
- git `db1a60a` · SLSA provenance + SPDX SBOM attached at publish
- `docker pull ghcr.io/darcstar-technologies/gide-isabelle-base@sha256:62089f75103f2aa11ed1227c6f541d691939bfcb7f649958378a54dbef9636ab`
- **Published by manual `workflow_dispatch`** (run 30513573516), not by the usual
  `workflow_run` chain. The mirror run for `db1a60a` concluded `failure` — its AFP
  leg published fine, but both Isabelle-distribution legs died on an upstream
  outage (`dist.isabelle.cit.tum.de:80` unreachable) even though that pin had not
  moved, and the old whole-run success gate then skipped the base rebuild twice.
  Both mirror tags this image `COPY --from=`s were present throughout, so the
  dispatched build is equivalent to what the chain would have produced. Fixed in
  [#67](https://github.com/DarcStar-Technologies/gide-public-images/issues/67)
  (per-leg independence + skip-if-present + a preflight that gates on the tags
  actually consumed).

### Source mirrors (verbatim upstream tarballs, `FROM scratch`)
- `gide-isabelle-source:Isabelle2025-2-{amd64,arm64}` — unchanged (see prior entry)
- `gide-afp-source:afp-2026-07-21` — `sha256:c4fd69e8dc7eb9b0374141abc82f70a929f83dce3eb2add0a91f7573c8f6e5ef`

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
