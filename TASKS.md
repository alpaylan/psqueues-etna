# psqueues — ETNA Tasks

Total tasks: 12

## Task Index

| Task | Variant | Framework | Property | Witness |
|------|---------|-----------|----------|---------|
| 001 | `hash_psq_insert_equal_priority_c107f38_1` | quickcheck | `HashPsqInsertEqualPriorityKeyTieBreak` | `witness_hash_psq_insert_equal_priority_key_tie_break_case_descending` |
| 002 | `hash_psq_insert_equal_priority_c107f38_1` | hedgehog | `HashPsqInsertEqualPriorityKeyTieBreak` | `witness_hash_psq_insert_equal_priority_key_tie_break_case_descending` |
| 003 | `hash_psq_insert_equal_priority_c107f38_1` | falsify | `HashPsqInsertEqualPriorityKeyTieBreak` | `witness_hash_psq_insert_equal_priority_key_tie_break_case_descending` |
| 004 | `hash_psq_insert_equal_priority_c107f38_1` | smallcheck | `HashPsqInsertEqualPriorityKeyTieBreak` | `witness_hash_psq_insert_equal_priority_key_tie_break_case_descending` |
| 005 | `ord_psq_balance_6a4a2b7_1` | quickcheck | `OrdPsqBalanceAfterOperations` | `witness_ord_psq_balance_after_operations_case_ascending_64` |
| 006 | `ord_psq_balance_6a4a2b7_1` | hedgehog | `OrdPsqBalanceAfterOperations` | `witness_ord_psq_balance_after_operations_case_ascending_64` |
| 007 | `ord_psq_balance_6a4a2b7_1` | falsify | `OrdPsqBalanceAfterOperations` | `witness_ord_psq_balance_after_operations_case_ascending_64` |
| 008 | `ord_psq_balance_6a4a2b7_1` | smallcheck | `OrdPsqBalanceAfterOperations` | `witness_ord_psq_balance_after_operations_case_ascending_64` |
| 009 | `ord_psq_from_list_37c12f5_1` | quickcheck | `OrdPsqFromListLastOccurrenceWins` | `witness_ord_psq_from_list_last_occurrence_wins_case_two_dup` |
| 010 | `ord_psq_from_list_37c12f5_1` | hedgehog | `OrdPsqFromListLastOccurrenceWins` | `witness_ord_psq_from_list_last_occurrence_wins_case_two_dup` |
| 011 | `ord_psq_from_list_37c12f5_1` | falsify | `OrdPsqFromListLastOccurrenceWins` | `witness_ord_psq_from_list_last_occurrence_wins_case_two_dup` |
| 012 | `ord_psq_from_list_37c12f5_1` | smallcheck | `OrdPsqFromListLastOccurrenceWins` | `witness_ord_psq_from_list_last_occurrence_wins_case_two_dup` |

## Witness Catalog

- `witness_hash_psq_insert_equal_priority_key_tie_break_case_descending` — Inserting (k=2,p=0) then (k=1,p=0) must leave findMin == Just (CK 1, 0, ...)
- `witness_hash_psq_insert_equal_priority_key_tie_break_case_three_apart` — Inserting (k=5,p=7) then (k=1,p=7) must leave findMin == Just (CK 1, 7, ...)
- `witness_ord_psq_balance_after_operations_case_ascending_64` — 64 ascending inserts must produce a tree that passes OrdPSQ.valid
- `witness_ord_psq_balance_after_operations_case_ascending_128` — 128 ascending inserts must produce a tree that passes OrdPSQ.valid
- `witness_ord_psq_from_list_last_occurrence_wins_case_two_dup` — fromList [(1,0,100),(1,0,200)] must give lookup 1 == Just (0,200)
- `witness_ord_psq_from_list_last_occurrence_wins_case_three_dup` — Mixed-key list with overrides at keys 1 and 2 must keep the last value/priority
