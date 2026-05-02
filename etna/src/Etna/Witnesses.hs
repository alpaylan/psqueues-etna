module Etna.Witnesses where

import Etna.Properties
import Etna.Result

------------------------------------------------------------------------------
-- Witnesses for OrdPSQFromListLastOccurrenceWins
--
-- A two-element list with the same key but different values: the second
-- value must win.
------------------------------------------------------------------------------

witness_ord_psq_from_list_last_occurrence_wins_case_two_dup :: PropertyResult
witness_ord_psq_from_list_last_occurrence_wins_case_two_dup =
  property_ord_psq_from_list_last_occurrence_wins
    (FromListArgs [(1, 0, 100), (1, 0, 200)])

witness_ord_psq_from_list_last_occurrence_wins_case_three_dup :: PropertyResult
witness_ord_psq_from_list_last_occurrence_wins_case_three_dup =
  property_ord_psq_from_list_last_occurrence_wins
    (FromListArgs [(1, 5, 100), (2, 3, 200), (1, 7, 300), (3, 1, 400), (2, 9, 500)])

------------------------------------------------------------------------------
-- Witnesses for HashPSQInsertEqualPriorityKeyTieBreak
--
-- Inserting (k=2, p=0) then (k=1, p=0) into a HashPSQ with colliding
-- hashes; the bucket head should end up at k=1 (smaller key wins).
------------------------------------------------------------------------------

witness_hash_psq_insert_equal_priority_key_tie_break_case_descending :: PropertyResult
witness_hash_psq_insert_equal_priority_key_tie_break_case_descending =
  property_hash_psq_insert_equal_priority_key_tie_break
    (EqPriorityArgs 2 1 0 200 100)

witness_hash_psq_insert_equal_priority_key_tie_break_case_three_apart :: PropertyResult
witness_hash_psq_insert_equal_priority_key_tie_break_case_three_apart =
  property_hash_psq_insert_equal_priority_key_tie_break
    (EqPriorityArgs 5 1 7 50 10)

------------------------------------------------------------------------------
-- Witnesses for OrdPSQBalanceAfterOperations
--
-- A monotonically-ascending sequence of inserts is the simplest pattern
-- that exposes the missing rebalancing: the new node always becomes the
-- right child of the existing tree, leaving the left side as a `Start`
-- and the right side deeply nested. The pre-fix `lbalance`/`rbalance`
-- short-circuited on the `Start` child.
------------------------------------------------------------------------------

witness_ord_psq_balance_after_operations_case_ascending_64 :: PropertyResult
witness_ord_psq_balance_after_operations_case_ascending_64 =
  property_ord_psq_balance_after_operations
    (BalanceArgs [OpInsert k k k | k <- [1 .. 64]])

witness_ord_psq_balance_after_operations_case_ascending_128 :: PropertyResult
witness_ord_psq_balance_after_operations_case_ascending_128 =
  property_ord_psq_balance_after_operations
    (BalanceArgs [OpInsert k k k | k <- [1 .. 128]])
