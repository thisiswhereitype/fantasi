{-# LANGUAGE OverloadedStrings #-}

module Tuura.Fantasi.VHDL.Internal.GraphWriter (
writeGraph
) where

-- TODO: Switch to ByteString

import Data.Maybe

import qualified Pangraph         as P

import Data.ByteString.Char8      (unpack)


type VertexName  = String
type VertexIndex = Int

-- The following two functions are written so that this file does not have to be rewritten to handle cases of Maybe

vertexValuesByKey :: P.Vertex -> P.Key -> [P.Value]
vertexValuesByKey v k = maybeToList $ lookup k (P.vertexAttributes v)

edgeValuesByKey :: P.Edge -> P.Key -> [P.Value]
edgeValuesByKey e k = maybeToList $ lookup k (P.edgeAttributes e)

-- | Writes a Pangraph to VHDL

writeGraph :: P.Pangraph -> String
writeGraph g = do
    let stats       = "-- Nodes: " ++ show (length $ P.vertexList g) ++ " - Edges: " ++ show (length $ P.edgeList g) ++ "\n"
        library     = createLibrary
        entity      = createEntity (P.vertexList g)
        archOpen    = openArchitecture g
        regs        = "\t-- Registers\n" ++ bindRegisters (P.vertexList g) 0
        wiresIn     = "\t-- Wire connections: inputs\n" ++ bindWiresIn g
        wiresOut    = "\t-- Wire connections: outputs\n" ++ bindWiresOut ((length (P.vertexList g)) -1)
        archClose   = closeArchitecture
    stats ++ library ++ entity ++ archOpen ++ regs ++ wiresIn ++ wiresOut ++ archClose

createLibrary :: String
createLibrary =     "-- File generated automatically\n"
                ++  "LIBRARY ieee;\n"
                ++  "USE ieee.std_logic_1164.all;\n\n"
                ++  "LIBRARY work;\n\n"

createEntity :: [P.Vertex] -> String
createEntity ns =   "ENTITY Graph IS\n"
                 ++ "\tPORT (\n"
                 ++ "\t\tCLK\t: IN\tstd_logic;\n"
                 ++ "\t\tRST\t: IN\tstd_logic;\n"
                 ++ "\t\tEN\t: IN\tstd_logic_vector(" ++ show (nNodes-1) ++ " downto 0);\n"
                 ++ "\t\tDIN\t: IN\tstd_logic_vector(" ++ show (nNodes-1) ++ " downto 0);\n"
                 ++ "\t\tDOUT\t: OUT\tstd_logic_vector(" ++ show (nNodes-1) ++ " downto 0));\n"
                 ++ "END Graph;\n\n"
                 where
                     nNodes = length ns

openArchitecture :: P.Pangraph -> String
openArchitecture p = do
    let open     = "ARCHITECTURE Graph_circuit OF Graph IS\n\n"
        register = createRegister
        sigs     = createSignals ns
        begin    = "BEGIN\n\n"
    open ++ register ++ sigs ++ begin
    where
      ns = P.vertexList p

closeArchitecture :: String
closeArchitecture = "\nEND Graph_circuit;"

bindWiresIn :: P.Pangraph -> String
bindWiresIn p = getStructure (P.vertexList p) (P.vertexList p)  (P.edgeList p)

bindWiresOut :: Int -> String
bindWiresOut 0 =   "\tDOUT(0) <= data_out(0);\n"
bindWiresOut n =   "\tDOUT(" ++ show n ++ ") <= data_out(" ++ show n ++ ");\n"
                ++ bindWiresOut (n-1)

getStructure :: [P.Vertex] -> [P.Vertex] -> [P.Edge] -> String
getStructure [] _ _ =   "\n"
getStructure (n:ns) nodes es =   "\tdata_in(" ++ show i ++ ") <=\tDIN(" ++ show i ++ ")"
                          ++ getInput (getConnections (unpack . head $ vertexValuesByKey n "id") nodes es)
                          ++ getStructure ns nodes es
                          where
                              i = getIndex (unpack . head $ vertexValuesByKey n "id") nodes 0

getInput :: [VertexIndex] -> String
getInput []     = ";\n"
getInput (ni:nis) = "\n\t\t\tOR data_out(" ++ show ni ++ ")" ++ getInput nis

createRegister :: String
createRegister =   "\tCOMPONENT ffd IS\n"
                ++ "\t\tPORT (\n"
                ++ "\t\t\tCLK\t: IN\tstd_logic;\n"
                ++ "\t\t\tRST\t: IN\tstd_logic;\n"
                ++ "\t\t\tEN\t: IN\tstd_logic;\n"
                ++ "\t\t\tD\t: IN\tstd_logic;\n"
                ++ "\t\t\tQ\t: OUT\tstd_logic\n"
                ++ "\t\t);\n"
                ++ "\tEND COMPONENT;\n\n"

createSignals :: [P.Vertex] -> String
createSignals ns = do
    let nRegs   = length ns
        sigsIn  = "\tSIGNAL data_in  : STD_LOGIC_VECTOR(" ++ show (nRegs-1) ++ " downto 0);\n"
        sigsOut = "\tSIGNAL data_out : STD_LOGIC_VECTOR(" ++ show (nRegs-1) ++ " downto 0);\n\n"
    sigsIn ++ sigsOut

bindRegisters :: [P.Vertex] -> Int -> String
bindRegisters [] _     = "\n"
bindRegisters (n:ns) i = bindRegister (unpack . head $ vertexValuesByKey n "id") i ++ bindRegisters ns (i+1)

bindRegister :: VertexName -> Int -> String
bindRegister name i =    "\tREG_" ++ name ++ " : ffd PORT MAP (\n"
                      ++ "\t\tCLK\t=>\tCLK,\n"
                      ++ "\t\tRST\t=>\tRST,\n"
                      ++ "\t\tEN\t=>\tEN(" ++ show i ++ "),\n"
                      ++ "\t\tD\t=>\tdata_in(" ++ show i ++ "),\n"
                      ++ "\t\tQ\t=>\tdata_out(" ++ show i ++ "));\n"

getIndex :: VertexName -> [P.Vertex] -> Int -> VertexIndex
getIndex nn [] _ = error $ "Node \"" ++ nn ++ "\" is not present in the graph"
getIndex n1 nb i -- = error $ show n1 ++ " !:! " ++ show nb
    | n1 == n2  = i
    | otherwise = getIndex n1 ns (i+1)
    where
      n2 = unpack . head $ vertexValuesByKey (head nb) "id"
      ns = tail nb

getConnections :: VertexName -> [P.Vertex] -> [P.Edge] -> [VertexIndex]
getConnections _ _ []         = []
getConnections name ns es
    | name == source    = getIndex target ns 0 : getConnections name ns (tail es)
    | name == target    = getIndex source ns 0 : getConnections name ns (tail es)
    | otherwise         = getConnections name ns (tail es)
    where
      source = unpack . head $ edgeValuesByKey (head es) "source"
      target = unpack . head $ edgeValuesByKey (head es) "target"
