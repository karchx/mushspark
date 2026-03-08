{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE OverloadedStrings #-}

module DB where

import Database.Beam
import Data.Text (Text)
import Data.Aeson (ToJSON(..), FromJSON, genericToJSON, defaultOptions, Options(..))
import Data.UUID (UUID)

data UserT f = User
    { _userId :: Columnar f UUID
    , _userUserName :: Columnar f Text
    , _email :: Columnar f Text
    } deriving (Generic, Beamable)

type User = UserT Identity
type UserId = PrimaryKey UserT Identity

instance ToJSON User where
    toJSON = genericToJSON defaultOptions
        { fieldLabelModifier = formatField }
        where
            formatField "_userId" = "id"
            formatField "_userUserName" = "name"
            formatField "_email" = "email"
            formatField other = other


instance FromJSON User

instance Table UserT where
    data PrimaryKey UserT f = UserId (Columnar f UUID) deriving (Generic, Beamable)
    primaryKey = UserId . _userId

data AppDb f = AppDb
    { _users :: f (TableEntity UserT)
    } deriving (Generic, Database be)

appDb :: DatabaseSettings be AppDb
appDb = defaultDbSettings

