# psqueues — ETNA workload

Upstream: <https://github.com/jaspervdj/psqueues>
Base commit: `e65ee4793b3ab3287397703d9c82a6168b74f875` (`v0.2.8.3`)
Language: Haskell (GHC 9.6.6)
Backends: QuickCheck, Hedgehog, Falsify, SmallCheck

## Layout

- `psqueues.cabal`, `src/`, `tests/`, ... — upstream sources, untouched
  except for one library-section change to `psqueues.cabal` that promotes
  `Data.OrdPSQ.Internal`, `Data.HashPSQ.Internal`, and `Data.IntPSQ.Internal`
  from `Other-modules` to `Exposed-modules`. The runner does not depend on
  this for any of the three current variants (they all reach the bug
  through `Data.OrdPSQ` / `Data.HashPSQ` public API), but exposing the
  internals keeps room open for future variants that need to inspect the
  tree shape directly.
- `cabal.project` — pins `packages: . etna/` and `with-compiler` to
  GHC 9.6.6 (Falsify ≥ 0.2 requires `base >= 4.18`, i.e. GHC ≥ 9.6).
- `etna/` — runner package (`etna-runner.cabal`, `app/Main.hs`,
  `src/Etna/...`, `test/Witnesses.hs`).
- `etna.toml` — manifest. Source of truth.
- `patches/<variant>.patch` — one synthetic patch per variant; reverse-
  applies against the base tree to install the historical bug.
- `BUGS.md`, `TASKS.md` — generated from `etna.toml` via
  `python scripts/check_haskell_workload.py . --regen-docs`. Never
  hand-edit.

## Running

```sh
cd workloads/Haskell/psqueues

# Base: every witness must Pass.
cabal test etna-witnesses

# Single property + single backend on base.
( cd etna && cabal run etna-runner -- quickcheck OrdPsqFromListLastOccurrenceWins )

# Reverse-apply a patch to install the bug, then drive each backend.
git apply -R --whitespace=nowarn patches/ord_psq_from_list_37c12f5_1.patch
( cd etna && cabal run etna-runner -- quickcheck OrdPsqFromListLastOccurrenceWins )
git apply    --whitespace=nowarn patches/ord_psq_from_list_37c12f5_1.patch
```

The runner prints a single JSON object per invocation:

```
{"status":"passed|failed|aborted","tests":N,"discards":0,"time":"<us>us",
 "counterexample":STRING|null,"error":STRING|null,
 "tool":"etna|quickcheck|hedgehog|falsify|smallcheck",
 "property":"<PropName>"}
```

## Variants (3 total, mined from upstream history)

1. `ord_psq_from_list_37c12f5_1` — `OrdPSQ.fromList` used `foldr` instead
   of `foldl'`, so the *first* occurrence of a duplicated key won
   (opposite of the documented contract).
2. `hash_psq_insert_equal_priority_c107f38_1` — `HashPSQ.insert` used a
   non-strict `p' <= p` priority guard with no key tie-break, so two keys
   inserted into a hash bucket with equal priority kept the first-inserted
   key as the bucket head regardless of key order.
3. `ord_psq_balance_6a4a2b7_1` — `lbalance`/`rbalance` short-circuited
   whenever either child was `Start`, even when the other child was deeply
   nested. Long ascending insert sequences produced trees that violated
   the omega-balance invariant (caught by `OrdPSQ.valid`).

## SmallCheck note

SmallCheck enumerates value trees by depth. Variant 3
(`OrdPsqBalanceAfterOperations`) needs ~64 ops to expose the imbalance,
which is far past any feasible SmallCheck depth — so that variant is
annotated `smallcheck_timeout = true` in the manifest. QuickCheck,
Hedgehog, and Falsify all detect it.
