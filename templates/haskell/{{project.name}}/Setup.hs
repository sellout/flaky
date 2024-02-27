{-# LANGUAGE PackageImports #-}

module Main where

import "cabal-doctest" Distribution.Extra.Doctest (defaultMainWithDoctests)

main :: IO ()
main = defaultMainWithDoctests "doctests"
