module Etna.Gens.QuickCheck where

import qualified Test.QuickCheck as QC

import           Etna.Properties

------------------------------------------------------------------------------
-- gen_ord_psq_from_list_last_occurrence_wins
--
-- Generates a list of (key, prio, value) triples drawing from a small
-- key pool so that duplicate keys are common -- otherwise every random
-- list would be all-unique and the bug would never trigger.
------------------------------------------------------------------------------

gen_ord_psq_from_list_last_occurrence_wins :: QC.Gen FromListArgs
gen_ord_psq_from_list_last_occurrence_wins = QC.sized $ \n -> do
  let len = min 12 (1 + n `div` 2)
  xs <- QC.vectorOf len $ do
    k <- QC.choose (0, 4)
    p <- QC.choose (-50, 50)
    v <- QC.arbitrary
    pure (k, p, v)
  pure (FromListArgs xs)

------------------------------------------------------------------------------
-- gen_hash_psq_insert_equal_priority_key_tie_break
--
-- Two distinct Int keys, a shared priority, and two value tags.
------------------------------------------------------------------------------

gen_hash_psq_insert_equal_priority_key_tie_break :: QC.Gen EqPriorityArgs
gen_hash_psq_insert_equal_priority_key_tie_break = do
  k1 <- QC.choose (-20, 20)
  k2 <- (QC.choose (-20, 20)) `QC.suchThat` (/= k1)
  p  <- QC.choose (-50, 50)
  v1 <- QC.arbitrary
  v2 <- QC.arbitrary
  pure (EqPriorityArgs k1 k2 p v1 v2)

------------------------------------------------------------------------------
-- gen_ord_psq_balance_after_operations
--
-- Sequence of insert/delete operations. Keys are drawn from a small
-- pool to keep deletes meaningful (a delete with a never-inserted key
-- is a no-op).
------------------------------------------------------------------------------

gen_ord_psq_balance_after_operations :: QC.Gen BalanceArgs
gen_ord_psq_balance_after_operations = QC.sized $ \n -> do
  let len = min 80 (4 + n)
  ops <- QC.vectorOf len genOp
  pure (BalanceArgs ops)

genOp :: QC.Gen BalanceOp
genOp = QC.frequency
  [ (4, OpInsert <$> QC.choose (0, 100)
                 <*> QC.choose (0, 100)
                 <*> QC.choose (0, 100))
  , (1, OpDelete <$> QC.choose (0, 100))
  ]
