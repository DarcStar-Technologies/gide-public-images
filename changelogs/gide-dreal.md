# Changelog — `gide-dreal`

Publish history for `ghcr.io/darcstar-technologies/gide-dreal` (dReal
delta-complete SMT solver on a minimal base; **amd64-only** — upstream ships an
`amd64` `.deb`). Format and conventions: see the [root CHANGELOG](../CHANGELOG.md).
Licenses: [THIRD-PARTY-NOTICES](../THIRD-PARTY-NOTICES.md).

## [4.21.06.2] — 2026-06-04
**Digest:** _published on merge — see GitHub Release `gide-dreal-4.21.06.2`._

### Composition (this repo) — regression fix, no upstream change
- **Removed `ENTRYPOINT ["dreal"]`** from `tools/dreal.Dockerfile`
  ([#52](https://github.com/DarcStar-Technologies/gide-public-images/issues/52)).
  The downstream `gide` portfolio harness invokes the image as
  `docker run <image> dreal <args>` (binary name passed explicitly, via the
  `/usr/local/bin/dreal` symlink). With the entrypoint set, that became
  `dreal dreal <args>`: dReal read the extra `dreal` token as a stray positional
  input-file argument and emitted **no verdict on `--in`** (empty stdout, exit 0)
  — breaking the SMT portfolio harness. The previous known-good build carried no
  entrypoint; this restores that contract byte-for-byte
  (`Entrypoint: null`, `Cmd: ["/bin/bash"]`).
- **Hardened the build smoke**: the prover `--version` smoke passed throughout the
  regression (the binary always self-reported v4.21.06.2). The dReal smoke now
  replicates the downstream contract — `docker run <img> dreal --in …` fed a
  known-`unsat` `QF_NRA` query on stdin — and gates promotion on an `unsat`
  verdict, catching this regression class and any future `--in` breakage.
- No upstream version change; same `dreal_4.21.06.2_amd64.deb`.

## [4.21.06.2] — 2026-06-03
**Digest:** `sha256:1e5e4850745ea7a907b20df35a30b556fe3ee412b5e66ded7b0379f220699888`

### Upstream
- dReal `4.21.06.2` — [release notes](https://github.com/dreal/dreal4/releases/tag/4.21.06.2) (Apache-2.0)

### Composition (this repo)
- The upstream package (`dreal_4.21.06.2_amd64.deb`) installed onto a minimal
  base; OCI `image.source` + `image.description` labels; smoke-tested with
  `--version` before promotion. Trivy-scanned by `scan-published-images.yml`.
- Auto-tracked by Renovate (github-releases). Initial published build (baseline).

### Provenance
- git `908b562` · SLSA provenance + SPDX SBOM attached at publish
- `docker pull ghcr.io/darcstar-technologies/gide-dreal@sha256:1e5e4850745ea7a907b20df35a30b556fe3ee412b5e66ded7b0379f220699888`
