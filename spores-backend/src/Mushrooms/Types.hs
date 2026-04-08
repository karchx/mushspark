{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE LambdaCase #-}

module Mushrooms.Types
    ( MushroomResponse(..)
    ) where

import Data.UUID (UUID)
import Data.Aeson (ToJSON(..), genericToJSON, defaultOptions, Options(..))
import GHC.Generics (Generic)

data MushroomResponse = MushroomResponse
    { mushroomId :: UUID
    , class_ :: String
    , capShape :: String
    , capSurface :: String
    , capColor :: String
    , season :: String
    } deriving (Generic)

instance ToJSON MushroomResponse where
    toJSON = genericToJSON defaultOptions
        { fieldLabelModifier = \case
            "mushroomId" -> "id"
            "class_" -> "class"
            other -> other
        }
