module Etna.Gens.Falsify where

import qualified Test.Falsify.Generator as F
import qualified Test.Falsify.Range     as FR

import           Etna.Properties

------------------------------------------------------------------------------
-- gen_ord_psq_from_list_last_occurrence_wins
------------------------------------------------------------------------------

gen_ord_psq_from_list_last_occurrence_wins :: F.Gen FromListArgs
gen_ord_psq_from_list_last_occurrence_wins = do
  n  <- F.integral (FR.between (0, 60))
  xs <- mapM (const tripleGen) [1 .. (n :: Int)]
  pure (FromListArgs xs)
  where
    tripleGen = do
      k <- F.integral (FR.between (0, 15))
      p <- F.integral (FR.between (-1000, 1000))
      v <- F.integral (FR.between (-1000, 1000))
      pure (k, p, v)

------------------------------------------------------------------------------
-- gen_hash_psq_insert_equal_priority_key_tie_break
------------------------------------------------------------------------------

gen_hash_psq_insert_equal_priority_key_tie_break :: F.Gen EqPriorityArgs
gen_hash_psq_insert_equal_priority_key_tie_break = do
  k1 <- F.integral (FR.between (-1000, 1000))
  k2 <- F.integral (FR.between (-1000, 1000))
  p  <- F.integral (FR.between (-1000, 1000))
  v1 <- F.integral (FR.between (-1000, 1000))
  v2 <- F.integral (FR.between (-1000, 1000))
  -- The property discards on k1 == k2; nudge one apart so we waste
  -- fewer cycles on discards.
  let k2' = if k2 == k1 then k1 + 1 else k2
  pure (EqPriorityArgs k1 k2' p v1 v2)

------------------------------------------------------------------------------
-- gen_ord_psq_balance_after_operations
------------------------------------------------------------------------------

gen_ord_psq_balance_after_operations :: F.Gen BalanceArgs
gen_ord_psq_balance_after_operations = do
  n   <- F.integral (FR.between (4, 200))
  ops <- mapM (const opGen) [1 .. (n :: Int)]
  pure (BalanceArgs ops)
  where
    opGen :: F.Gen BalanceOp
    opGen = do
      tag <- F.integral (FR.between (0, 5 :: Int))
      if tag == 0
        then OpDelete <$> F.integral (FR.between (0, 1000))
        else OpInsert <$> F.integral (FR.between (0, 1000))
                      <*> F.integral (FR.between (0, 1000))
                      <*> F.integral (FR.between (0, 1000))
