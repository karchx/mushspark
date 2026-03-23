{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE OverloadedStrings #-}

module FSM.Recommendation
    ( ActiveStatus(..)
    , TerminalStatus(..)
    , RecommendationStatus(..)
    , RecommendationEvent(..)
    , TransitionError(..)
    , transition
    , statusToText
    , textToStatus
    , textToEvent
    ) where

import Data.Text (Text)
import Data.Aeson (FromJSON, ToJSON)
import GHC.Generics (Generic)

data ActiveStatus = Pending | Viewed
    deriving (Show, Eq, Generic, FromJSON, ToJSON)

data TerminalStatus = Accepted | Rejected | Expired
    deriving (Show, Eq, Generic, FromJSON, ToJSON)

data RecommendationStatus
    = Active ActiveStatus
    | Terminal TerminalStatus
    deriving (Show, Eq, Generic, FromJSON, ToJSON)

data RecommendationEvent
    = EventView
    | EventAccept
    | EventReject
    | EventExpire
    deriving (Show, Eq)

data TransitionError
    = InvalidTransition ActiveStatus RecommendationEvent
    deriving (Show, Eq)

transition :: ActiveStatus -> RecommendationEvent -> Either TransitionError RecommendationStatus
transition Pending EventView = Right (Active Viewed)
transition Pending EventExpire = Right (Terminal Expired)
transition Viewed EventAccept = Right (Terminal Accepted)
transition Viewed EventReject = Right (Terminal Rejected)
transition Viewed EventExpire = Right (Terminal Expired)
transition s e                = Left (InvalidTransition s e)

statusToText :: RecommendationStatus -> Text
statusToText (Active Pending)    = "pending"
statusToText (Active Viewed)     = "viewed"
statusToText (Terminal Accepted) = "accepted"
statusToText (Terminal Rejected) = "rejected"
statusToText (Terminal Expired)  = "expired"

textToStatus :: Text -> Maybe RecommendationStatus
textToStatus "pending"  = Just (Active Pending)
textToStatus "viewed"   = Just (Active Viewed)
textToStatus "accepted" = Just (Terminal Accepted)
textToStatus "rejected" = Just (Terminal Rejected)
textToStatus "expired"  = Just (Terminal Expired)
textToStatus _          = Nothing

textToEvent :: Text -> Maybe RecommendationEvent
textToEvent "view"   = Just EventView
textToEvent "accept" = Just EventAccept
textToEvent "reject" = Just EventReject
textToEvent "expire" = Just EventExpire
textToEvent _        = Nothing
