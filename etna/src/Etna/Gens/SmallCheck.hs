{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
module Etna.Gens.SmallCheck where

import qualified Test.SmallCheck.Series as SC
import           Test.SmallCheck.Series  ((\/), (><))

import           Etna.Properties

------------------------------------------------------------------------------
-- series_ord_psq_from_list_last_occurrence_wins
--
-- Enumerate small key/prio/val tuples drawn from a 5-key universe (0..4)
-- so duplicate keys appear at low depth.
------------------------------------------------------------------------------

series_ord_psq_from_list_last_occurrence_wins
  :: Monad m => SC.Series m FromListArgs
series_ord_psq_from_list_last_occurrence_wins =
  FromListArgs <$> SC.series

instance Monad m => SC.Serial m EqPriorityArgs where
  series = SC.decDepth $
    EqPriorityArgs
      <$> SC.series
      <*> SC.series
      <*> SC.series
      <*> SC.series
      <*> SC.series

------------------------------------------------------------------------------
-- series_hash_psq_insert_equal_priority_key_tie_break
------------------------------------------------------------------------------

series_hash_psq_insert_equal_priority_key_tie_break
  :: Monad m => SC.Series m EqPriorityArgs
series_hash_psq_insert_equal_priority_key_tie_break = SC.series

------------------------------------------------------------------------------
-- series_ord_psq_balance_after_operations
------------------------------------------------------------------------------

instance Monad m => SC.Serial m BalanceOp where
  series = SC.decDepth $
        (OpInsert <$> SC.series <*> SC.series <*> SC.series)
    \/  (OpDelete <$> SC.series)

series_ord_psq_balance_after_operations
  :: Monad m => SC.Series m BalanceArgs
series_ord_psq_balance_after_operations =
  BalanceArgs <$> SC.series
