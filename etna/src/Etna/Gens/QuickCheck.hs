module Etna.Gens.QuickCheck where

import qualified Test.QuickCheck as QC

import           Etna.Properties

------------------------------------------------------------------------------
-- gen_ord_psq_from_list_last_occurrence_wins
--
-- A list of (key, priority, value) triples. Keys are drawn from a
-- moderately small pool so duplicate keys are common (the bug only
-- shows up when the same key appears more than once in the list);
-- priorities and values span the full Int range that the upstream
-- psqueues test suite uses.
------------------------------------------------------------------------------

gen_ord_psq_from_list_last_occurrence_wins :: QC.Gen FromListArgs
gen_ord_psq_from_list_last_occurrence_wins = QC.sized $ \n -> do
  len <- QC.choose (0, max 0 (min 60 (4 + n)))
  xs  <- QC.vectorOf len $ do
    k <- QC.choose (0, 15)
    p <- QC.choose (-1000, 1000)
    v <- QC.choose (-1000, 1000)
    pure (k, p, v)
  pure (FromListArgs xs)

------------------------------------------------------------------------------
-- gen_hash_psq_insert_equal_priority_key_tie_break
--
-- Two distinct Int keys, a shared priority, and two value tags.
-- Ranges cover the upstream psqueues test convention (-1000..1000) so
-- the random pair is more representative of library-faithful input.
------------------------------------------------------------------------------

gen_hash_psq_insert_equal_priority_key_tie_break :: QC.Gen EqPriorityArgs
gen_hash_psq_insert_equal_priority_key_tie_break = do
  k1 <- QC.choose (-1000, 1000)
  k2 <- (QC.choose (-1000, 1000)) `QC.suchThat` (/= k1)
  p  <- QC.choose (-1000, 1000)
  v1 <- QC.choose (-1000, 1000)
  v2 <- QC.choose (-1000, 1000)
  pure (EqPriorityArgs k1 k2 p v1 v2)

------------------------------------------------------------------------------
-- gen_ord_psq_balance_after_operations
--
-- Sequence of insert/delete operations, mirroring the upstream
-- arbitraryPSQ pattern (random count of actions, keys spanning the
-- 0..1000 range that the psqueues test suite uses). Inserts dominate
-- so the tree grows enough for the omega-balance invariant to be
-- exercised.
------------------------------------------------------------------------------

gen_ord_psq_balance_after_operations :: QC.Gen BalanceArgs
gen_ord_psq_balance_after_operations = QC.sized $ \n -> do
  len <- QC.choose (4, max 4 (min 200 (10 + n)))
  ops <- QC.vectorOf len genOp
  pure (BalanceArgs ops)

genOp :: QC.Gen BalanceOp
genOp = QC.frequency
  [ (5, OpInsert <$> QC.choose (0, 1000)
                 <*> QC.choose (0, 1000)
                 <*> QC.choose (0, 1000))
  , (1, OpDelete <$> QC.choose (0, 1000))
  ]
