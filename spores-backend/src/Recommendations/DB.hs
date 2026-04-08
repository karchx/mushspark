{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE OverloadedStrings #-}

module Recommendations.DB
    ( RecommendationT(..)
    , Recommendation
    , RecommendationId
    , EventRecommendationT(..)
    , EventRecommendation
    , EventRecommendationId
    , PrimaryKey(..)
    , AppDB(..)
    , appDb
    ) where

import Database.Beam
import Data.Text (Text)
import Data.Aeson (ToJSON(..), FromJSON (parseJSON), genericToJSON, defaultOptions, Options(..))
import Data.UUID (UUID)

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
    data PrimaryKey RecommendationT f = RecommendationKey (Columnar f UUID) deriving (Generic, Beamable)
    primaryKey = RecommendationKey . _recommendationId

data EventRecommendationT f = EventRecommendation
    { _erId :: Columnar f UUID
    , _erRecommendationId :: PrimaryKey RecommendationT f -- foreign key
    , _erStatus :: Columnar f Text
    } deriving (Generic, Beamable)

type EventRecommendation = EventRecommendationT Identity
type EventRecommendationId = PrimaryKey EventRecommendationT Identity

-- Instance JSON for PrimaryKey
instance ToJSON RecommendationId where
    toJSON (RecommendationKey uid) = toJSON uid

instance FromJSON RecommendationId where
    parseJSON v = RecommendationKey <$> parseJSON v

instance Table EventRecommendationT where
    data PrimaryKey EventRecommendationT f = EventRecommendationId (Columnar f UUID) deriving (Generic, Beamable)
    primaryKey = EventRecommendationId . _erId

instance FromJSON EventRecommendation
instance ToJSON EventRecommendation where
    toJSON = genericToJSON defaultOptions
        { fieldLabelModifier = formatField }
        where
            formatField "_erId" = "id"
            formatField "_erRecommendationId" = "recommendationId"
            formatField "_erStatus" = "status"
            formatField "_erCreatedAt" = "createdAt"
            formatField other = other


data AppDB f = AppDB
    { _recommendations :: f (TableEntity RecommendationT)
    , _eventsRecommendation :: f (TableEntity EventRecommendationT)
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
    , _eventsRecommendation = setEntityName "events_recommendation" <> modifyTableFields tableModification
        { _erId = "id"
        , _erRecommendationId = RecommendationKey "recommendation_id"
        , _erStatus = "status"
        }
    }

