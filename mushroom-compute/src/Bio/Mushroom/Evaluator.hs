{-# LANGUAGE OverloadedStrings #-}
module Bio.Mushroom.Evaluator (evalExpr) where

import Bio.Mushroom.AST
import qualified Data.Text as T
import qualified Data.Text.IO as TIO

evalExpr :: Expr -> IO ()
evalExpr (CalcToxicityVariance species) = 
    TIO.putStrLn $ "Execution: SELECT variance((chemical_composition->>'toxicityLevel')::numeric) FROM mushrooms WHERE genus = '" <> species <> "'"
evalExpr (FilterPhenotype trait val) =
    TIO.putStrLn $ "Execution: SELECT id, species FROM mushrooms WHERE phenotype_data @> '{\"" <> trait <> "\": \"" <> val <> "\"}'"
evalExpr (RunPCA features) =
    TIO.putStrLn $ "Construyendo matriz hmatrix para PCA sobre: " <> (T.pack $ show features)

evalExpr (CombineExpr e1 e2) = do
    evalExpr e1
    evalExpr e2
