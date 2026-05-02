module Bio.Mushroom.Types 
    ( Phenotype(..)
    , ChemicalComp(..)
    ) where

import Data.Text (Text)

data Phenotype = Phenotype
    { capColor :: Text
    , gillType :: Text
    } deriving (Show, Eq)

data ChemicalComp = ChemicalComp
    { psilocybinMg :: Double
    , toxicityLevel :: Double
    } deriving (Show, Eq)

