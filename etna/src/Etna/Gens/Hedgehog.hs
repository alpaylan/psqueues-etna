module Etna.Gens.Hedgehog where

import qualified Hedgehog       as HH
import qualified Hedgehog.Gen   as Gen
import qualified Hedgehog.Range as Range

import           Etna.Properties

------------------------------------------------------------------------------
-- gen_ord_psq_from_list_last_occurrence_wins
------------------------------------------------------------------------------

gen_ord_psq_from_list_last_occurrence_wins :: HH.Gen FromListArgs
gen_ord_psq_from_list_last_occurrence_wins = do
  xs <- Gen.list (Range.linear 0 60) $ do
    k <- Gen.int (Range.linear 0 15)
    p <- Gen.int (Range.linearFrom 0 (-1000) 1000)
    v <- Gen.int (Range.linearFrom 0 (-1000) 1000)
    pure (k, p, v)
  pure (FromListArgs xs)

------------------------------------------------------------------------------
-- gen_hash_psq_insert_equal_priority_key_tie_break
------------------------------------------------------------------------------

gen_hash_psq_insert_equal_priority_key_tie_break :: HH.Gen EqPriorityArgs
gen_hash_psq_insert_equal_priority_key_tie_break = do
  k1 <- Gen.int (Range.linearFrom 0 (-1000) 1000)
  k2 <- Gen.filter (/= k1) (Gen.int (Range.linearFrom 0 (-1000) 1000))
  p  <- Gen.int (Range.linearFrom 0 (-1000) 1000)
  v1 <- Gen.int (Range.linearFrom 0 (-1000) 1000)
  v2 <- Gen.int (Range.linearFrom 0 (-1000) 1000)
  pure (EqPriorityArgs k1 k2 p v1 v2)

------------------------------------------------------------------------------
-- gen_ord_psq_balance_after_operations
------------------------------------------------------------------------------

gen_ord_psq_balance_after_operations :: HH.Gen BalanceArgs
gen_ord_psq_balance_after_operations = do
  ops <- Gen.list (Range.linear 4 200) genOp
  pure (BalanceArgs ops)

genOp :: HH.Gen BalanceOp
genOp = Gen.frequency
  [ (5, OpInsert <$> Gen.int (Range.linear 0 1000)
                 <*> Gen.int (Range.linear 0 1000)
                 <*> Gen.int (Range.linear 0 1000))
  , (1, OpDelete <$> Gen.int (Range.linear 0 1000))
  ]
