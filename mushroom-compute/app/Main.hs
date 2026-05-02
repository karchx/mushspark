{-# LANGUAGE OverloadedStrings #-}
module Main (main) where

import Bio.Mushroom.AST
import Bio.Mushroom.Parser (parseQuery)
import Bio.Mushroom.Evaluator (evalExpr)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO

main :: IO ()
main = do
    let testQueries =
            [ "calc_toxicity_variance(Amanita)"
            , "filter_phenotype(cap_color, red)"
            , "run_pca(cap_color, cap_shape, gill_color)"
            ]

    mapM_ processRequest testQueries

processRequest :: T.Text -> IO ()
processRequest query =
    case parseQuery query of
        Left err ->
            TIO.putStrLn $ "[Parse Error] " <> T.pack (show err)
        Right expr -> 
            TIO.putStrLn $ "[AST] " <> T.pack (show expr)
            evalExpr expr

