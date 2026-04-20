{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE OverloadedStrings #-}

module Mushrooms.DB
    ( MushroomT(..)
    , Mushroom
    , MushroomId
    , PrimaryKey(..)
    , AppDB(..)
    , appDb
    ) where


import Database.Beam
import Data.Text (Text)
import Data.Aeson (ToJSON(..), FromJSON (..), genericToJSON, defaultOptions, Options(..))
import Data.UUID (UUID)

data MushroomT f = Mushroom
    { _mushroomId :: Columnar f UUID
    , _class :: Columnar f Text
    , _capShape :: Columnar f Text
    , _capSurface :: Columnar f Text
    , _capColor :: Columnar f Text
    , _season :: Columnar f (Maybe Text)
    } deriving (Generic, Beamable)

type Mushroom = MushroomT Identity
type MushroomId = PrimaryKey MushroomT Identity

instance FromJSON Mushroom
instance ToJSON Mushroom where
    toJSON = genericToJSON defaultOptions
        { fieldLabelModifier = formatField }
        where
            formatField "_mushroomId" = "id"
            formatField "_class" = "class"
            formatField "_capShape" = "capShape"
            formatField "_capSurface" = "capSurface"
            formatField "_capColor" = "capColor"
            formatField "_season" = "season"
            formatField other = other

instance Table MushroomT where
    data PrimaryKey MushroomT f = MushroomKey (Columnar f UUID) deriving (Generic, Beamable)
    primaryKey = MushroomKey . _mushroomId


data AppDB f = AppDB
    { _mushroom :: f (TableEntity MushroomT)
    } deriving (Generic, Database be)

appDb :: DatabaseSettings be AppDB
appDb = defaultDbSettings `withDbModification` dbModification
    { _mushroom = setEntityName "mushroom" <> modifyTableFields tableModification
        { _mushroomId = "id"
        , _class      = "class"
        , _capShape   = "cap_shape"
        , _capSurface = "cap_surface"
        , _capColor   = "cap_color"
        , _season     = "season"
        }
    }

