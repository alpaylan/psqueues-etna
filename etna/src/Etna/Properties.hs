{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE ScopedTypeVariables #-}
module Etna.Properties where

import           Etna.Result

import           Data.Hashable           (Hashable (..))
import qualified Data.HashPSQ            as HashPSQ
import qualified Data.OrdPSQ             as OrdPSQ

------------------------------------------------------------------------------
-- Args types (one per property)
------------------------------------------------------------------------------

newtype FromListArgs = FromListArgs { fromListItems :: [(Int, Int, Int)] }
  deriving (Eq, Show)

data EqPriorityArgs = EqPriorityArgs
  { epK1 :: !Int
  , epK2 :: !Int
  , epPrio :: !Int
  , epV1 :: !Int
  , epV2 :: !Int
  } deriving (Eq, Show)

newtype BalanceArgs = BalanceArgs { balanceOps :: [BalanceOp] }
  deriving (Eq, Show)

data BalanceOp
  = OpInsert !Int !Int !Int  -- key prio val
  | OpDelete !Int            -- key
  deriving (Eq, Show)

------------------------------------------------------------------------------
-- CollidingKey: forces every value into a single HashPSQ bucket so the
-- bucket-head tie-break logic can be exercised without depending on the
-- platform's hashable instance.
------------------------------------------------------------------------------

newtype CollidingKey = CK Int deriving (Eq, Ord)

instance Show CollidingKey where
  show (CK n) = "CK " ++ show n

instance Hashable CollidingKey where
  hash _              = 0
  hashWithSalt salt _ = salt

------------------------------------------------------------------------------
-- Property 1: OrdPSQFromListLastOccurrenceWins
--
-- Documented contract of OrdPSQ.fromList:
--   "If the list contains more than one priority and value for the same
--    key, the last priority and value for the key is retained."
--
-- The pre-fix implementation used `foldr (\(k,p,v) q -> insert k p v q)`
-- which actually retains the FIRST occurrence (foldr processes the list
-- right-to-left; the leftmost call to `insert` ends up overwriting later
-- entries).
------------------------------------------------------------------------------

property_ord_psq_from_list_last_occurrence_wins
  :: FromListArgs -> PropertyResult
property_ord_psq_from_list_last_occurrence_wins (FromListArgs xs) =
  let q :: OrdPSQ.OrdPSQ Int Int Int
      q = OrdPSQ.fromList xs
      ks = uniqueKeys xs
      mismatches =
        [ (k, actual, expected)
        | k <- ks
        , let actual   = OrdPSQ.lookup k q
              expected = lastOccurrence k xs
        , actual /= expected
        ]
  in case mismatches of
       []          -> Pass
       (k, a, e):_ -> Fail ("fromList: key " ++ show k ++
                            ": got "      ++ show a ++
                            ", expected " ++ show e)

uniqueKeys :: [(Int, Int, Int)] -> [Int]
uniqueKeys = foldr step []
  where
    step (k, _, _) acc
      | k `elem` acc = acc
      | otherwise    = k : acc

lastOccurrence :: Int -> [(Int, Int, Int)] -> Maybe (Int, Int)
lastOccurrence k = foldl step Nothing
  where
    step _   (k', p, v) | k' == k = Just (p, v)
    step acc _                    = acc

------------------------------------------------------------------------------
-- Property 2: HashPSQInsertEqualPriorityKeyTieBreak
--
-- When two items share a hash bucket and have equal priority, the bucket
-- head must be the one with the smaller key (the deterministic
-- tie-break rule encoded by the modern `p' < p || (p == p' && k' < k)`
-- branch). The pre-fix `p' <= p` form short-circuits before the
-- tie-break, so whichever item happened to be inserted first stays at
-- the head -- and `findMin` therefore reports the wrong key/value.
------------------------------------------------------------------------------

property_hash_psq_insert_equal_priority_key_tie_break
  :: EqPriorityArgs -> PropertyResult
property_hash_psq_insert_equal_priority_key_tie_break
    (EqPriorityArgs k1 k2 p v1 v2)
  | k1 == k2  = Discard
  | otherwise =
      let q :: HashPSQ.HashPSQ CollidingKey Int Int
          q = HashPSQ.insert (CK k2) p v2
            $ HashPSQ.insert (CK k1) p v1
            $ HashPSQ.empty
          (kMin, vMin) = if k1 < k2 then (k1, v1) else (k2, v2)
          actual   = HashPSQ.findMin q
          expected = Just (CK kMin, p, vMin)
      in if actual == expected
           then Pass
           else Fail ("findMin: got "      ++ show actual ++
                      ", expected "        ++ show expected ++
                      " (inserts: k1=" ++ show k1 ++
                      ", k2=" ++ show k2 ++ ", p=" ++ show p ++ ")")

------------------------------------------------------------------------------
-- Property 3: OrdPSQBalanceAfterOperations
--
-- After an arbitrary sequence of insert/delete operations, the
-- internal `valid` predicate must hold. Modern `valid` includes
-- `hasBalancedTreeProperty`; the pre-fix `lbalance`/`rbalance` short-
-- circuited the omega rebalancing whenever one child was `Start`,
-- producing trees that satisfy the BST/heap invariants but violate the
-- omega-balance invariant. `OrdPSQ.valid` flags this directly.
------------------------------------------------------------------------------

property_ord_psq_balance_after_operations
  :: BalanceArgs -> PropertyResult
property_ord_psq_balance_after_operations (BalanceArgs ops) =
  let q = applyBalanceOps ops (OrdPSQ.empty :: OrdPSQ.OrdPSQ Int Int Int)
  in if OrdPSQ.valid q
       then Pass
       else Fail ("OrdPSQ.valid is False after " ++
                  show (length ops) ++ " operations: " ++
                  showOps ops)

applyBalanceOps
  :: [BalanceOp]
  -> OrdPSQ.OrdPSQ Int Int Int
  -> OrdPSQ.OrdPSQ Int Int Int
applyBalanceOps ops q0 = foldl step q0 ops
  where
    step q (OpInsert k p v) = OrdPSQ.insert k p v q
    step q (OpDelete k)     = OrdPSQ.delete k q

showOps :: [BalanceOp] -> String
showOps ops = case ops of
  []                  -> "[]"
  _ | length ops <= 8 -> show ops
    | otherwise       -> "(" ++ show (length ops) ++ " ops, head=" ++
                         show (take 3 ops) ++ ")"
