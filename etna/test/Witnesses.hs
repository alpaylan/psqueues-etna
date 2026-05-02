module Main where

import Etna.Result    (PropertyResult(..))
import Etna.Witnesses
import System.Exit    (exitFailure, exitSuccess)

main :: IO ()
main = do
  let cases :: [(String, PropertyResult)]
      cases =
        [ ( "witness_ord_psq_from_list_last_occurrence_wins_case_two_dup"
          , witness_ord_psq_from_list_last_occurrence_wins_case_two_dup )
        , ( "witness_ord_psq_from_list_last_occurrence_wins_case_three_dup"
          , witness_ord_psq_from_list_last_occurrence_wins_case_three_dup )
        , ( "witness_hash_psq_insert_equal_priority_key_tie_break_case_descending"
          , witness_hash_psq_insert_equal_priority_key_tie_break_case_descending )
        , ( "witness_hash_psq_insert_equal_priority_key_tie_break_case_three_apart"
          , witness_hash_psq_insert_equal_priority_key_tie_break_case_three_apart )
        , ( "witness_ord_psq_balance_after_operations_case_ascending_64"
          , witness_ord_psq_balance_after_operations_case_ascending_64 )
        , ( "witness_ord_psq_balance_after_operations_case_ascending_128"
          , witness_ord_psq_balance_after_operations_case_ascending_128 )
        ]
  let failures = [(n, msg) | (n, Fail msg) <- cases]
                 ++ [(n, "discard") | (n, Discard) <- cases]
  if null failures
    then exitSuccess
    else do
      mapM_ (\(n, m) -> putStrLn (n ++ ": " ++ m)) failures
      exitFailure
