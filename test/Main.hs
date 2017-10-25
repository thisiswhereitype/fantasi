module Main (
main
) where

import Test.HUnit

import Pangraph.GraphML.Parser
import Tuura.Fantasi.VHDL.Writer
import VHDLLiterals

main :: IO Counts
main = runTestTT $ TestList[case1, case2]

case1 :: Test
case1 = TestCase $ assertEqual "case1: Enviroment Writer N1"
  enviroFile1 (writeEnvironment $ unsafeParse graphfileN1)

case2 :: Test
case2 = TestCase $ assertEqual "case2: Graph Writer N1"
  vhdlGraph1 (writeGraph $ unsafeParse graphfileN1)
