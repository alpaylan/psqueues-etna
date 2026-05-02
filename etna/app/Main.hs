{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main where

import           Control.Exception     (SomeException, evaluate, try)
import           Data.IORef            (newIORef, readIORef, modifyIORef')
import           Data.Time.Clock       (diffUTCTime, getCurrentTime)
import           System.Environment    (getArgs)
import           System.Exit           (exitWith, ExitCode(..))
import           System.IO             (hFlush, stdout)
import           System.IO.Unsafe      (unsafePerformIO)
import           Text.Printf           (printf)

import           Etna.Result           (PropertyResult(..))
import qualified Etna.Properties       as P
import qualified Etna.Witnesses        as W
import qualified Etna.Gens.QuickCheck  as GQ
import qualified Etna.Gens.Hedgehog    as GH
import qualified Etna.Gens.Falsify     as GF
import qualified Etna.Gens.SmallCheck  as GS

import qualified Test.QuickCheck                    as QC
import qualified Hedgehog                           as HH
import qualified Test.Falsify.Generator             as FG
import qualified Test.Falsify.Interactive           as FI
import qualified Test.Falsify.Property              as FP
import qualified Test.SmallCheck                    as SC
import qualified Test.SmallCheck.Drivers             as SCD
import qualified Test.SmallCheck.Series              as SCS

allProperties :: [String]
allProperties =
  [ "OrdPsqFromListLastOccurrenceWins"
  , "HashPsqInsertEqualPriorityKeyTieBreak"
  , "OrdPsqBalanceAfterOperations"
  ]

data Outcome = Outcome
  { oStatus :: String
  , oTests  :: Int
  , oCex    :: Maybe String
  , oErr    :: Maybe String
  }

main :: IO ()
main = do
  argv <- getArgs
  case argv of
    [tool, prop] -> dispatch tool prop
    _            -> do
      putStrLn "{\"status\":\"aborted\",\"error\":\"usage: etna-runner <tool> <property>\"}"
      hFlush stdout
      exitWith (ExitFailure 2)

dispatch :: String -> String -> IO ()
dispatch tool prop
  | prop /= "All" && prop `notElem` allProperties =
      emit tool prop "aborted" 0 0 Nothing (Just $ "unknown property: " ++ prop)
  | otherwise = do
      let targets = if prop == "All" then allProperties else [prop]
      mapM_ (runOne tool) targets

runOne :: String -> String -> IO ()
runOne tool prop = do
  t0 <- getCurrentTime
  result <- try (driver tool prop) :: IO (Either SomeException Outcome)
  t1 <- getCurrentTime
  let us = round ((realToFrac (diffUTCTime t1 t0) :: Double) * 1e6) :: Int
  case result of
    Left e  -> emit tool prop "aborted" 0 us Nothing (Just (show e))
    Right (Outcome status tests cex err) ->
      emit tool prop status tests us cex err

driver :: String -> String -> IO Outcome
driver "etna"       p = runWitnesses p
driver "quickcheck" p = runQuickCheck p
driver "hedgehog"   p = runHedgehog   p
driver "falsify"    p = runFalsify    p
driver "smallcheck" p = runSmallCheck p
driver tool         _ = pure (Outcome "aborted" 0 Nothing (Just ("unknown tool: " ++ tool)))

------------------------------------------------------------------------------
-- Tool: etna (witness replay)
------------------------------------------------------------------------------

runWitnesses :: String -> IO Outcome
runWitnesses prop = case witnessesFor prop of
  []    -> pure (Outcome "aborted" 0 Nothing (Just ("no witnesses for " ++ prop)))
  cs    -> go cs 0
  where
    go [] n = pure (Outcome "passed" n Nothing Nothing)
    go ((name, r):rest) n = do
      forced <- try (evaluate r) :: IO (Either SomeException PropertyResult)
      case forced of
        Left e  -> pure (Outcome "failed" (n + 1) (Just name) (Just (show e)))
        Right Pass     -> go rest (n + 1)
        Right Discard  -> go rest (n + 1)
        Right (Fail m) -> pure (Outcome "failed" (n + 1) (Just name) (Just m))

-- Force a property result inside pure code, catching runtime exceptions
-- thrown by the library-under-test. Used by the Falsify adapter (which
-- has no IO escape inside its 'Property' monad); mirrors QC.ioProperty
-- / HH.evalIO / SC.monadic for the other backends.
safeEval :: PropertyResult -> Either String PropertyResult
safeEval pr = unsafePerformIO $ do
  r <- try (evaluate pr) :: IO (Either SomeException PropertyResult)
  pure $ case r of
    Left e  -> Left (show e)
    Right v -> Right v
{-# NOINLINE safeEval #-}

witnessesFor :: String -> [(String, PropertyResult)]
witnessesFor "OrdPsqFromListLastOccurrenceWins" =
  [ ( "witness_ord_psq_from_list_last_occurrence_wins_case_two_dup"
    , W.witness_ord_psq_from_list_last_occurrence_wins_case_two_dup )
  , ( "witness_ord_psq_from_list_last_occurrence_wins_case_three_dup"
    , W.witness_ord_psq_from_list_last_occurrence_wins_case_three_dup )
  ]
witnessesFor "HashPsqInsertEqualPriorityKeyTieBreak" =
  [ ( "witness_hash_psq_insert_equal_priority_key_tie_break_case_descending"
    , W.witness_hash_psq_insert_equal_priority_key_tie_break_case_descending )
  , ( "witness_hash_psq_insert_equal_priority_key_tie_break_case_three_apart"
    , W.witness_hash_psq_insert_equal_priority_key_tie_break_case_three_apart )
  ]
witnessesFor "OrdPsqBalanceAfterOperations" =
  [ ( "witness_ord_psq_balance_after_operations_case_ascending_64"
    , W.witness_ord_psq_balance_after_operations_case_ascending_64 )
  , ( "witness_ord_psq_balance_after_operations_case_ascending_128"
    , W.witness_ord_psq_balance_after_operations_case_ascending_128 )
  ]
witnessesFor _ = []

------------------------------------------------------------------------------
-- Tool: quickcheck
------------------------------------------------------------------------------

runQuickCheck :: String -> IO Outcome
runQuickCheck "OrdPsqFromListLastOccurrenceWins" =
  qcDrive (QC.forAll GQ.gen_ord_psq_from_list_last_occurrence_wins
            (qcProp P.property_ord_psq_from_list_last_occurrence_wins))
runQuickCheck "HashPsqInsertEqualPriorityKeyTieBreak" =
  qcDrive (QC.forAll GQ.gen_hash_psq_insert_equal_priority_key_tie_break
            (qcProp P.property_hash_psq_insert_equal_priority_key_tie_break))
runQuickCheck "OrdPsqBalanceAfterOperations" =
  qcDrive (QC.forAll GQ.gen_ord_psq_balance_after_operations
            (qcProp P.property_ord_psq_balance_after_operations))
runQuickCheck p = pure (Outcome "aborted" 0 Nothing (Just ("unknown property: " ++ p)))

qcProp :: (a -> PropertyResult) -> a -> QC.Property
qcProp f args = QC.ioProperty $ do
  r <- try (evaluate (f args)) :: IO (Either SomeException PropertyResult)
  pure $ case r of
    Left e          -> QC.counterexample (show e) (QC.property False)
    Right Pass      -> QC.property True
    Right Discard   -> QC.discard
    Right (Fail m)  -> QC.counterexample m (QC.property False)

qcDrive :: QC.Property -> IO Outcome
qcDrive p = do
  result <- QC.quickCheckWithResult
              QC.stdArgs { QC.maxSuccess = 200, QC.chatty = False }
              p
  case result of
    QC.Success { QC.numTests = n } -> pure (Outcome "passed" n Nothing Nothing)
    QC.Failure { QC.numTests = n, QC.failingTestCase = tc } ->
      pure (Outcome "failed" n (Just (concat tc)) Nothing)
    QC.GaveUp  { QC.numTests = n } -> pure (Outcome "aborted" n Nothing (Just "QuickCheck gave up"))
    QC.NoExpectedFailure { QC.numTests = n } ->
      pure (Outcome "aborted" n Nothing (Just "no expected failure"))

------------------------------------------------------------------------------
-- Tool: hedgehog
------------------------------------------------------------------------------

runHedgehog :: String -> IO Outcome
runHedgehog "OrdPsqFromListLastOccurrenceWins" =
  hhDrive GH.gen_ord_psq_from_list_last_occurrence_wins
          P.property_ord_psq_from_list_last_occurrence_wins
runHedgehog "HashPsqInsertEqualPriorityKeyTieBreak" =
  hhDrive GH.gen_hash_psq_insert_equal_priority_key_tie_break
          P.property_hash_psq_insert_equal_priority_key_tie_break
runHedgehog "OrdPsqBalanceAfterOperations" =
  hhDrive GH.gen_ord_psq_balance_after_operations
          P.property_ord_psq_balance_after_operations
runHedgehog p = pure (Outcome "aborted" 0 Nothing (Just ("unknown property: " ++ p)))

hhDrive :: (Show a) => HH.Gen a -> (a -> PropertyResult) -> IO Outcome
hhDrive gen f = do
  let test = HH.property $ do
        args <- HH.forAll gen
        r <- HH.evalIO (try (evaluate (f args))
                          :: IO (Either SomeException PropertyResult))
        case r of
          Left e         -> do
            HH.annotate (show e)
            HH.failure
          Right Pass     -> pure ()
          Right Discard  -> HH.discard
          Right (Fail m) -> do
            HH.annotate m
            HH.failure
  ok <- HH.check test
  if ok
    then pure (Outcome "passed" 200 Nothing Nothing)
    else pure (Outcome "failed" 1 Nothing Nothing)

------------------------------------------------------------------------------
-- Tool: falsify
------------------------------------------------------------------------------

runFalsify :: String -> IO Outcome
runFalsify "OrdPsqFromListLastOccurrenceWins" =
  fsDrive GF.gen_ord_psq_from_list_last_occurrence_wins
          P.property_ord_psq_from_list_last_occurrence_wins
runFalsify "HashPsqInsertEqualPriorityKeyTieBreak" =
  fsDrive GF.gen_hash_psq_insert_equal_priority_key_tie_break
          P.property_hash_psq_insert_equal_priority_key_tie_break
runFalsify "OrdPsqBalanceAfterOperations" =
  fsDrive GF.gen_ord_psq_balance_after_operations
          P.property_ord_psq_balance_after_operations
runFalsify p = pure (Outcome "aborted" 0 Nothing (Just ("unknown property: " ++ p)))

fsDrive :: (Show a) => FG.Gen a -> (a -> PropertyResult) -> IO Outcome
fsDrive gen f = do
  let prop = do
        args <- FP.gen gen
        case safeEval (f args) of
          Left e         -> FP.testFailed (show args ++ ": " ++ e)
          Right Pass     -> pure ()
          Right Discard  -> FP.discard
          Right (Fail m) -> FP.testFailed (show args ++ ": " ++ m)
  mFailure <- FI.falsify prop
  case mFailure of
    Nothing  -> pure (Outcome "passed" 100 Nothing Nothing)
    Just msg -> pure (Outcome "failed" 1 (Just msg) Nothing)

------------------------------------------------------------------------------
-- Tool: smallcheck
------------------------------------------------------------------------------

runSmallCheck :: String -> IO Outcome
runSmallCheck "OrdPsqFromListLastOccurrenceWins" =
  scDrive GS.series_ord_psq_from_list_last_occurrence_wins
          P.property_ord_psq_from_list_last_occurrence_wins
runSmallCheck "HashPsqInsertEqualPriorityKeyTieBreak" =
  scDrive GS.series_hash_psq_insert_equal_priority_key_tie_break
          P.property_hash_psq_insert_equal_priority_key_tie_break
runSmallCheck "OrdPsqBalanceAfterOperations" =
  scDrive GS.series_ord_psq_balance_after_operations
          P.property_ord_psq_balance_after_operations
runSmallCheck p = pure (Outcome "aborted" 0 Nothing (Just ("unknown property: " ++ p)))

scDrive :: (Show a) => SCS.Series IO a -> (a -> PropertyResult) -> IO Outcome
scDrive series f = do
  countRef <- newIORef (0 :: Int)
  let depth = 4
      check args = SC.monadic $ do
        modifyIORef' countRef (+1)
        r <- try (evaluate (f args))
               :: IO (Either SomeException PropertyResult)
        pure $ case r of
          Left _         -> False
          Right Pass     -> True
          Right Discard  -> True
          Right (Fail _) -> False
      smTest = SC.over series check
  res <- try (SCD.smallCheckM depth smTest)
           :: IO (Either SomeException (Maybe SCD.PropertyFailure))
  n <- readIORef countRef
  case res of
    Left e          -> pure (Outcome "failed" n Nothing (Just (show e)))
    Right Nothing   -> pure (Outcome "passed" n Nothing Nothing)
    Right (Just pf) -> pure (Outcome "failed" n (Just (show pf)) Nothing)

------------------------------------------------------------------------------
-- Output (single JSON line, exit 0 except on argv error)
------------------------------------------------------------------------------

emit :: String -> String -> String -> Int -> Int -> Maybe String -> Maybe String -> IO ()
emit tool prop status tests us cex err = do
  let q = quoteJSON
      esc Nothing  = "null"
      esc (Just s) = q s
  printf "{\"status\":%s,\"tests\":%d,\"discards\":0,\"time\":\"%dus\",\"counterexample\":%s,\"error\":%s,\"tool\":%s,\"property\":%s}\n"
    (q status) tests us (esc cex) (esc err) (q tool) (q prop)
  hFlush stdout

quoteJSON :: String -> String
quoteJSON s = '"' : concatMap esc s ++ "\""
  where
    esc '"'  = "\\\""
    esc '\\' = "\\\\"
    esc '\n' = "\\n"
    esc '\r' = "\\r"
    esc '\t' = "\\t"
    esc c | fromEnum c < 0x20 = printf "\\u%04x" (fromEnum c)
          | otherwise = [c]
