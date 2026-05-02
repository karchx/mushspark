module Bio.Mushroom.AST 
    ( Expr(..)
    ) where

import Data.Text (Text)

data Expr
    = CalcToxicityVariance Text
    | FilterPhenotype Text Text
    | RunPCA [Text]
    | CombineExpr Expr Expr
    deriving (Show, Eq)

