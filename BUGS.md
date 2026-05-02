# psqueues — Injected Bugs

Jasper Van der Jeugt's `psqueues` package (jaspervdj/psqueues): pure priority search queues in three flavours (OrdPSQ, IntPSQ, HashPSQ). Bug fixes mined from upstream history; modern HEAD is the base, each patch reverse-applies a fix to install the original bug.

Total mutations: 3

## Bug Index

| # | Variant | Name | Location | Injection | Fix Commit |
|---|---------|------|----------|-----------|------------|
| 1 | `hash_psq_insert_equal_priority_c107f38_1` | `hash_psq_insert_drops_smaller_key_at_equal_priority` | `src/Data/HashPSQ/Internal.hs:184` | `patch` | `c107f382d7c93692e0bb64140c4f6823f25d76e1` |
| 2 | `ord_psq_balance_6a4a2b7_1` | `lbalance_skips_rebalance_on_start_child` | `src/Data/OrdPSQ/Internal.hs:522` | `patch` | `6a4a2b735be37099738ace78c28a252dd5391a39` |
| 3 | `ord_psq_from_list_37c12f5_1` | `from_list_first_occurrence_wins` | `src/Data/OrdPSQ/Internal.hs:292` | `patch` | `37c12f5cef9962ca92d4198a5a3ed400e8c64e73` |

## Property Mapping

| Variant | Property | Witness(es) |
|---------|----------|-------------|
| `hash_psq_insert_equal_priority_c107f38_1` | `HashPsqInsertEqualPriorityKeyTieBreak` | `witness_hash_psq_insert_equal_priority_key_tie_break_case_descending`, `witness_hash_psq_insert_equal_priority_key_tie_break_case_three_apart` |
| `ord_psq_balance_6a4a2b7_1` | `OrdPsqBalanceAfterOperations` | `witness_ord_psq_balance_after_operations_case_ascending_64`, `witness_ord_psq_balance_after_operations_case_ascending_128` |
| `ord_psq_from_list_37c12f5_1` | `OrdPsqFromListLastOccurrenceWins` | `witness_ord_psq_from_list_last_occurrence_wins_case_two_dup`, `witness_ord_psq_from_list_last_occurrence_wins_case_three_dup` |

## Framework Coverage

| Property | quickcheck | hedgehog | falsify | smallcheck |
|----------|---------:|-------:|------:|---------:|
| `HashPsqInsertEqualPriorityKeyTieBreak` | ✓ | ✓ | ✓ | ✓ |
| `OrdPsqBalanceAfterOperations` | ✓ | ✓ | ✓ | ✓ |
| `OrdPsqFromListLastOccurrenceWins` | ✓ | ✓ | ✓ | ✓ |

## Bug Details

### 1. hash_psq_insert_drops_smaller_key_at_equal_priority

- **Variant**: `hash_psq_insert_equal_priority_c107f38_1`
- **Location**: `src/Data/HashPSQ/Internal.hs:184` (inside `insert`)
- **Property**: `HashPsqInsertEqualPriorityKeyTieBreak`
- **Witness(es)**:
  - `witness_hash_psq_insert_equal_priority_key_tie_break_case_descending` — Inserting (k=2,p=0) then (k=1,p=0) must leave findMin == Just (CK 1, 0, ...)
  - `witness_hash_psq_insert_equal_priority_key_tie_break_case_three_apart` — Inserting (k=5,p=7) then (k=1,p=7) must leave findMin == Just (CK 1, 7, ...)
- **Source**: internal — HashPSQ.valid (and fix bug found using valid...)
  > Pre-fix `HashPSQ.insert` used a non-strict priority comparison `p' <= p` to decide whether the existing bucket head should stay or whether the incoming item should take its place. When two distinct keys hash to the same `IntPSQ` slot and are inserted with *equal* priority, `<=` keeps whichever item was inserted first as the bucket head -- regardless of which key is smaller. The fix introduced a strict `p' < p || (p == p' && k' < k)` form that breaks ties by key. The patch reverts the priority guard to `p' <= p`.
- **Fix commit**: `c107f382d7c93692e0bb64140c4f6823f25d76e1` — HashPSQ.valid (and fix bug found using valid...)
- **Invariant violated**: For any two distinct keys `k1`, `k2` that share a hash slot and any priority `p`, `findMin (insert k2 p v2 (insert k1 p v1 empty))` equals `Just (min k1 k2, p, v_min)` where `v_min` is the value associated with the smaller key.
- **How the mutation triggers**: Reverse-applying the patch turns the strict priority+key comparison back into `p' <= p`. When the second insert has the same priority but a smaller key, the buggy version drops it into the OrdPSQ tail instead of promoting it to the bucket head, so `findMin` returns the larger key.

### 2. lbalance_skips_rebalance_on_start_child

- **Variant**: `ord_psq_balance_6a4a2b7_1`
- **Location**: `src/Data/OrdPSQ/Internal.hs:522` (inside `lbalance`)
- **Property**: `OrdPsqBalanceAfterOperations`
- **Witness(es)**:
  - `witness_ord_psq_balance_after_operations_case_ascending_64` — 64 ascending inserts must produce a tree that passes OrdPSQ.valid
  - `witness_ord_psq_balance_after_operations_case_ascending_128` — 128 ascending inserts must produce a tree that passes OrdPSQ.valid
- **Source**: internal — Fix OrdPSQ tree balancing logic. fixes #60 (#61)
  > Pre-fix `lbalance`/`rbalance` short-circuited unconditionally whenever either child was `Start` (a leaf), regardless of how deeply nested the opposite child was. This was an attempted optimisation of Hinze's original paper, but it skipped the omega-rebalancing trigger on inserts at the boundary -- so a long ascending insert sequence produces a tree that satisfies the BST and heap invariants but violates the omega-balance invariant. The fix reverted to the paper's formulation (with a `size' r + size' l < 2` guard for the trivial cases). The patch reverts to the historical short-circuit form.
- **Fix commit**: `6a4a2b735be37099738ace78c28a252dd5391a39` — Fix OrdPSQ tree balancing logic. fixes #60 (#61)
- **Invariant violated**: After an arbitrary sequence of `insert` and `delete` operations, `OrdPSQ.valid q` must return `True` (which on modern HEAD includes the omega-balance check `hasBalancedTreeProperty`).
- **How the mutation triggers**: Reverse-applying the patch puts back the `Start`-child short-circuits in `lbalance`/`rbalance`. A monotonically-ascending insert sequence repeatedly hits the short-circuit (the left child stays `Start`, the right grows unbounded), so the resulting tree fails `hasBalancedTreeProperty` and `valid` returns `False`.

### 3. from_list_first_occurrence_wins

- **Variant**: `ord_psq_from_list_37c12f5_1`
- **Location**: `src/Data/OrdPSQ/Internal.hs:292` (inside `fromList`)
- **Property**: `OrdPsqFromListLastOccurrenceWins`
- **Witness(es)**:
  - `witness_ord_psq_from_list_last_occurrence_wins_case_two_dup` — fromList [(1,0,100),(1,0,200)] must give lookup 1 == Just (0,200)
  - `witness_ord_psq_from_list_last_occurrence_wins_case_three_dup` — Mixed-key list with overrides at keys 1 and 2 must keep the last value/priority
- **Source**: internal — Fix the fromList implementation (#50)
  > Pre-fix `OrdPSQ.fromList` was `foldr (\(k,p,v) q -> insert k p v q) empty`. `foldr` processes the input list right-to-left, so when an item with key `k` is followed by another item with the same key, the *first* occurrence is the one that ends up in the queue -- the opposite of the function's documented contract ("the last priority and value for the key is retained"). The fix swapped to `foldl'`. The patch reverts to the historical `foldr` formulation.
- **Fix commit**: `37c12f5cef9962ca92d4198a5a3ed400e8c64e73` — Fix the fromList implementation (#50)
- **Invariant violated**: For every list `xs :: [(k, p, v)]` and every key `k` that appears in `xs`, `lookup k (fromList xs)` equals `(p, v)` for the *last* (k, p, v) triple in `xs` whose key matches.
- **How the mutation triggers**: Reverse-applying the patch swaps `foldl'` for `foldr`. For any list with at least two entries sharing a key, the buggy `fromList` retains the first-encountered (k, p, v) and discards subsequent ones, so `lookup` returns the wrong (p, v) pair.
