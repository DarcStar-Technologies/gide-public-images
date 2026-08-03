# Changelog — `gide-z3`

Publish history for `ghcr.io/darcstar-technologies/gide-z3` (Z3 SMT solver
binary on a minimal base; **amd64 + arm64**). Format and conventions: see the
[root CHANGELOG](../CHANGELOG.md). Licenses:
[THIRD-PARTY-NOTICES](../THIRD-PARTY-NOTICES.md).

<!-- renovate-pr-75 -->
## [5.0.0] — 2026-08-03
**Digest:** _published on merge — see GitHub Release `gide-z3-5.0.0`._

### Upstream
- Z3 `5.0.0` — [release notes](https://github.com/Z3Prover/z3/releases/tag/z3-5.0.0)

<details><summary>Upstream release notes (captured from PR #75)</summary>

### [`v5.0.0`](https://redirect.github.com/Z3Prover/z3/blob/HEAD/RELEASE_NOTES.md#Version-500)

[Compare Source](https://redirect.github.com/Z3Prover/z3/compare/z3-4.16.0...z3-5.0.0)

\==============

- A FiniteSets theory solver
  FiniteSets is a theory with a sort (FiniteSet S) for base sort S.
  Inhabitants of (FiniteSet S) are finite sets of elements over S.
  The main operations are creating empty sets, singleton sets, union, intersection, set difference, ranges of integers, subset modulo a predicate.
  Constraints are: membership, subset.
  The size of a set is obtained using set.size.
  It is possible to map a function over elements of a set using set.map.
  Support for set.range, set.map is partial.
  Support for set.size exists, but is without any optimization. The source code contains comments on ways to make it more efficient. File a GitHub issue if you want to contribute.s
- Add Python API convenience methods for improved usability. Thanks to Daniel Tang.
  - Solver.solutions(t) method for finding all solutions to constraints, [#&#8203;8633](https://redirect.github.com/Z3Prover/z3/pull/8633)
  - ArithRef.**abs** alias to integrate with Python's abs() builtin, [#&#8203;8623](https://redirect.github.com/Z3Prover/z3/pull/8623)
  - Improved error message in ModelRef.**getitem** to suggest using eval(), [#&#8203;8626](https://redirect.github.com/Z3Prover/z3/pull/8626)
  - Documentation example for Solver.sexpr(), [#&#8203;8631](https://redirect.github.com/Z3Prover/z3/pull/8631)
- Performance improvements by replacing unnecessary copy operations with std::move semantics for better efficiency.
  Thanks to Nuno Lopes, [#&#8203;8583](https://redirect.github.com/Z3Prover/z3/pull/8583)
- Fix spurious sort error with nested quantifiers in model finder. `Fixes #&#8203;8563`
- NLSAT optimizations including improvements to handle\_nullified\_poly and levelwise algorithm. Thanks to Lev Nachmanson.
- Add ASan/UBSan memory safety CI workflow for continuous runtime safety checking. Thanks to Angelica Moreira.
  [#&#8203;8856](https://redirect.github.com/Z3Prover/z3/pull/8856)
- Add missing API bindings across multiple languages:
  - Python: BvNand, BvNor, BvXnor operations, Optimize.translate()
  - Go: MkAsArray, MkRecFuncDecl, AddRecDef, Model.Translate, MkBVRotateLeft, MkBVRotateRight, MkRepeat, and 8 BV overflow/underflow check functions
  - TypeScript: Array.fromFunc, Model.translate
  - OCaml: Model.translate, mk\_re\_allchar (thanks to Filipe Marques, [#&#8203;8785](https://redirect.github.com/Z3Prover/z3/pull/8785))
  - Java: as-array method (thanks to Ruijie Fang, [#&#8203;8762](https://redirect.github.com/Z3Prover/z3/pull/8762))
- Fix [#&#8203;7507](https://redirect.github.com/Z3Prover/z3/issues/7507): simplify (>= product\_of\_consecutive\_ints 0) to true
- Fix [#&#8203;7951](https://redirect.github.com/Z3Prover/z3/issues/7951): add cancellation checks to polynomial gcd\_prs and HNF computation
- Fix [#&#8203;7677](https://redirect.github.com/Z3Prover/z3/issues/7677): treat FC\_CONTINUE from check\_nla as FEASIBLE in maximize
- Fix assertion violation in q\_mbi diagnostic output
- Fix memory leaks in model\_based\_opt def ref-counting
- Fix NoSuchFieldError in JNI for BoolPtr: use Z field descriptor and SetBooleanField
- Fix TypeScript Array.fromFunc to use f.ptr instead of f.ast for Z3\_func\_decl type
- Fix intblast ubv\_to\_int bug: add bv2int axioms for compound expressions
- Fix static analysis findings: uninitialized variables, bitwise shift undefined behavior, and null pointer dereferences
- Convert bv1-blast and blast-term-ite tactics to also expose as simplifiers for more flexible integration
- Change default of param lws\_subs\_witness\_disc to true for improved NLSAT performance. Thanks to Lev Nachmanson.
- Nl2Lin integrates a linear under-approximation of a CAD cell by Valentin Promies for improved NLSAT performance on nonlinear arithmetic problems.
  [#&#8203;8982](https://redirect.github.com/Z3Prover/z3/pull/8982)
- Fix incorrect optimization of mod in box mode. Fixes [#&#8203;9012](https://redirect.github.com/Z3Prover/z3/issues/9012)
- Fix inconsistent optimization with scaled objectives in the LP optimizer when nonlinear constraints prevent exploration of the full feasible region.
  [#&#8203;8998](https://redirect.github.com/Z3Prover/z3/pull/8998)
- Fix NLA optimization regression and improve LP restore\_x handling.
  [#&#8203;8944](https://redirect.github.com/Z3Prover/z3/pull/8944)
- Enable sum of monomials simplification in the optimizer for improved nonlinear arithmetic optimization.
- Convert injectivity and special-relations tactics to simplifier-based implementations for better integration with the simplifier pipeline.
  [#&#8203;8954](https://redirect.github.com/Z3Prover/z3/pull/8954), [#&#8203;8955](https://redirect.github.com/Z3Prover/z3/pull/8955)
- Fix assertion violation in mpz.cpp when running with -tr:arith tracing.
  [#&#8203;8945](https://redirect.github.com/Z3Prover/z3/pull/8945)
- Additional API improvements:
  - Java: numeral extraction helpers (getInt, getLong, getDouble for ArithExpr and BitVecNum). Thanks to Angelica Moreira, [#&#8203;8978](https://redirect.github.com/Z3Prover/z3/pull/8978)
  - Java: missing AST query methods (isTrue, isFalse, isNot, isOr, isAnd, isDistinct, getBoolValue, etc.). Thanks to Angelica Moreira, [#&#8203;8977](https://redirect.github.com/Z3Prover/z3/pull/8977)
  - Go: Goal, FuncEntry, Model APIs; TypeScript: Seq higher-order operations (map, fold). [#&#8203;9006](https://redirect.github.com/Z3Prover/z3/pull/9006)
- Fix API coherence issues across Go, Java, C++, and TypeScript bindings.
  [#&#8203;8983](https://redirect.github.com/Z3Prover/z3/pull/8983)
- Fix deep API bugs in Z3 C API (null pointer handling, error propagation).
  [#&#8203;8972](https://redirect.github.com/Z3Prover/z3/pull/8972)
- Implement multivariate polynomial factorization via Hensel lifting. Replaces the prior stub
  implementation (factor\_n\_sqf\_pp) with a working algorithm: evaluate away extra variables to
  reduce to bivariate, factor the univariate specialization, lift via linear Hensel lifting in
  Zp\[x], and verify the result over Z\[x,y]. For more than two variables, bivariate factors are
  checked against the original polynomial. Thanks to Lev Nachmanson.
- Add riscv64 Python wheel builds to nightly and release PyPI publishing.
  [#&#8203;9153](https://redirect.github.com/Z3Prover/z3/pull/9153)
- Fix nlsat clear() crash: reset polynomial cache and root-atom assignments during solver
  destruction to prevent use-after-free heap corruption. Also fix scoped\_numeral\_vector copy
  constructor to read from the source operand instead of uninitialized self.
  [#&#8203;9150](https://redirect.github.com/Z3Prover/z3/pull/9150)
- Fix [#&#8203;9030](https://redirect.github.com/Z3Prover/z3/issues/9030): in box mode optimization (opt.priority=box), each objective is now optimized
  independently using push/pop scopes, so adding or removing one objective no longer changes
  the optimal values of others.
- Fix assertion violation in isolate\_roots for nested nlsat calls. Fixes [#&#8203;6871](https://redirect.github.com/Z3Prover/z3/issues/6871).
- Fix [#&#8203;9036](https://redirect.github.com/Z3Prover/z3/issues/9036): expand bounded integer quantifiers in qe-light when Fourier-Motzkin elimination
  fails due to non-unit coefficients. When all remaining quantified integers have explicit

</details>

### Composition (this repo)
- Bumped to `5.0.0` (from `4.16.0`) via Renovate (#75).


## [4.16.0] — 2026-06-03
**Digest:** `sha256:1e3437a8ad7f3e92602b7cb124ce2850ceb331857ed51e318b5276fedb4ea66e`

### Upstream
- Z3 `4.16.0` — [release notes](https://github.com/Z3Prover/z3/releases/tag/z3-4.16.0) (MIT)

### Composition (this repo)
- The upstream release archive (`z3-4.16.0-<plat>.zip`) extracted onto a minimal
  base; OCI `image.source` + `image.description` labels; smoke-tested with
  `--version` before promotion. Trivy-scanned by `scan-published-images.yml`.
- Auto-tracked by Renovate (github-releases). Initial published build (baseline).

### Provenance
- git `908b562` · SLSA provenance + SPDX SBOM attached at publish
- `docker pull ghcr.io/darcstar-technologies/gide-z3@sha256:1e3437a8ad7f3e92602b7cb124ce2850ceb331857ed51e318b5276fedb4ea66e`
