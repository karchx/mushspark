{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}

module Recommendations.Types 
    ( CreateRecommendationRequest(..)
    , RecommendationResponse(..)
    , ApplyEvent(..)
    , CreateEventRecommendationRequest(..)
    , EventRecommendationResponse(..)
    ) where

import Data.UUID (UUID)
import Data.Aeson (FromJSON, ToJSON)
import Data.Text (Text)
import GHC.Generics (Generic)
import FSM.Recommendation (RecommendationStatus)

data CreateRecommendationRequest = CreateRecommendationRequest
    { fromUserId :: UUID
    , mushroomId :: UUID
    , note :: Maybe Text
    } deriving (Generic, FromJSON)

data RecommendationResponse = RecommendationResponse
    { recommendationId  :: UUID
    , fromUserId        :: UUID
    , toUserId          :: Maybe UUID
    , mushroomId        :: UUID
    , status            :: RecommendationStatus
    , note              :: Maybe Text
    } deriving (Generic, ToJSON)


data ApplyEvent = ApplyEvent
    { recommendationId  :: UUID
    , event :: Text 
    } deriving (Generic, FromJSON)

data CreateEventRecommendationRequest = CreateEventRecommendationRequest
    { recommendationId :: UUID
    , status :: Text
    } deriving (Generic, FromJSON)

data EventRecommendationResponse = EventRecommendationResponse
    { erId :: UUID
    , recommendationId :: UUID
    , status :: Text
    } deriving (Generic, ToJSON)

