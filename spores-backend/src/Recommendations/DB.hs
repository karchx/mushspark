{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE OverloadedStrings #-}

module Recommendations.DB (
    RecommendationT(..),
    Recommendation,
    RecommendationId,
    AppDB(..),
    appDb
) where

import Database.Beam
import Data.Text (Text)
import Data.Aeson (ToJSON(..), FromJSON, genericToJSON, defaultOptions, Options(..))
import Data.UUID (UUID)
-- import Data.Time (UTCTime)

data RecommendationT f = Recommendation
    { _recommendationId :: Columnar f UUID
    , _fromUserId       :: Columnar f UUID
    , _toUserId         :: Columnar f (Maybe UUID)
    , _mushroomId       :: Columnar f UUID
    , _status           :: Columnar f Text
    , _note             :: Columnar f (Maybe Text)
    -- , _createdAt        :: Columnar f UTCTime
    -- , _updatedAt        :: Columnar f UTCTime
    } deriving (Generic, Beamable)

type Recommendation = RecommendationT Identity
type RecommendationId = PrimaryKey RecommendationT Identity

instance FromJSON Recommendation
instance ToJSON Recommendation where
    toJSON = genericToJSON defaultOptions
        { fieldLabelModifier = formatField }
        where
            formatField "_recommendationId" = "id"
            formatField "_fromUserId" = "fromUserId"
            formatField "_toUserId" = "toUserId"
            formatField "_mushroomId" = "mushroomId"
            formatField "_status" = "status"
            formatField "_note" = "note"
            formatField other = other

instance Table RecommendationT where
    data PrimaryKey RecommendationT f = RecommendationId (Columnar f UUID) deriving (Generic, Beamable)
    primaryKey = RecommendationId . _recommendationId

data AppDB f = AppDB
    { _recommendations :: f (TableEntity RecommendationT)
    } deriving (Generic, Database be)

appDb :: DatabaseSettings be AppDB
appDb = defaultDbSettings `withDbModification` dbModification
    { _recommendations = setEntityName "recommendations" <> modifyTableFields tableModification
        { _recommendationId = "id"
        , _fromUserId       = "from_user_id"
        , _toUserId         = "to_user_id"
        , _mushroomId       = "mushroom_id"
        , _status           = "status"
        , _note             = "note"
        }
    }
