{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}

module Recommendations.Handler 
    ( createRecommendation
    , applyEvent
    ) where

import Control.Monad.Catch (try)
import Data.Aeson (encode, object, (.=))
import Database.Beam
import Database.Beam.Postgres (SqlError(..))
import Database.Beam.Backend.SQL.BeamExtensions (runInsertReturningList, MonadBeamUpdateReturning (runUpdateReturningList))
import Servant (throwError, err409, err404, err500, errBody, errHeaders, err400)
import Recommendations.Types (CreateRecommendationRequest(..), RecommendationResponse(..), ApplyEvent(..), CreateEventRecommendationRequest(..), EventRecommendationResponse(..))
import Types (AppM)
import Auth (AuthenticatedUser(..))
import Data.UUID (UUID)
import Data.Text (Text)
import Recommendations.DB 
    ( RecommendationT(..)
    , EventRecommendationT (..)
    , PrimaryKey(..)
    , Recommendation
    , appDb
    , _recommendations
    , AppDB (_eventsRecommendation)
    , EventRecommendation
    )
import FSM.Recommendation(RecommendationStatus(..), ActiveStatus(..), TransitionError(..), statusToText, textToStatus, transition, textToEvent)
import DB (runDb)

createRecommendation :: AuthenticatedUser -> CreateRecommendationRequest -> AppM RecommendationResponse
createRecommendation authUser req = do
    let insertQuery = insert (_recommendations appDb) $
            insertExpressions
                [ Recommendation 
                    default_
                    (val_ (auUserId authUser))
                    (val_ (Nothing :: Maybe UUID))
                    (val_ (req.mushroomId)) 
                    (val_ (statusToText (Active Pending)))
                    (val_ (req.note)) 
                ]
    insertedRecs <- try $ runDb $ runInsertReturningList insertQuery

    case insertedRecs of
        Left e@(SqlError { sqlState = state })
            | state == "23505" ->
                let jsonPayload = object ["message" .= ("Recommendation already exists" :: Text)]
                in throwError err409 { errBody = encode jsonPayload, errHeaders = [("Content-Type", "application/json")] }
            | otherwise         -> 
                let jsonPayload = object ["message" .= ("Internal database error" :: Text), "error" .= show e]
                in throwError err500 { errBody = encode jsonPayload, errHeaders = [("Content-Type", "application/json")] }

        Right (newRecommendation:_) -> do
            let eventReq = CreateEventRecommendationRequest
                    { recommendationId = _recommendationId newRecommendation
                    , status = _status newRecommendation
                    }
            _ <- createEventRecommendation eventReq
            return $ toResponse newRecommendation
        Right []                    -> throwError err500 { errBody = "Failed to create recommendation" }

    where
        toResponse :: Recommendation -> RecommendationResponse
        toResponse dbRec = RecommendationResponse
            { recommendationId  = _recommendationId dbRec
            , fromUserId        = _fromUserId dbRec
            , toUserId          = _toUserId dbRec
            , mushroomId        = _mushroomId dbRec
            , status            = case textToStatus (_status dbRec) of
                                    Just s -> s
                                    Nothing -> Active Pending
            , note              = _note dbRec
            }

createEventRecommendation :: CreateEventRecommendationRequest -> AppM EventRecommendationResponse
createEventRecommendation req = do
    let insertQuery = insert (_eventsRecommendation appDb) $
            insertExpressions
                [ EventRecommendation
                    default_
                    (val_ (RecommendationKey req.recommendationId))
                    (val_ (req.status))
                ]
    insertedEventRecs <- try $ runDb $ runInsertReturningList insertQuery

    case insertedEventRecs of
        Left e@(SqlError { sqlState = state })
            | state == "23505" ->
                let jsonPayload = object ["message" .= ("Recommendation already exists" :: Text)]
                in throwError err409 { errBody = encode jsonPayload, errHeaders = [("Content-Type", "application/json")] }
            | otherwise         -> 
                let jsonPayload = object ["message" .= ("Internal database error" :: Text), "error" .= show e]
                in throwError err500 { errBody = encode jsonPayload, errHeaders = [("Content-Type", "application/json")] }

        Right (newRecommendation:_) -> return $ toResponse newRecommendation
        Right []                    -> throwError err500 { errBody = "Failed to create recommendation" }
    where
        toResponse :: EventRecommendation -> EventRecommendationResponse
        toResponse dbRec =
            let (RecommendationKey uuid) = _erRecommendationId dbRec
            in EventRecommendationResponse
                { erId = _erId dbRec
                , recommendationId = uuid
                , status = _erStatus dbRec
                }


applyEvent
    :: AuthenticatedUser
    -> ApplyEvent
    -> AppM RecommendationResponse
applyEvent authUser (ApplyEvent recId rawEvent) = do
    -- Fetch the current recommendation from the database
    mRec <- runDb $ runSelectReturningOne $ select $ do
        rec <- all_ (_recommendations appDb)
        guard_ (_recommendationId rec ==. val_ recId)
        return rec

    rec <- case mRec of
        Nothing -> throwError err404 { errBody = encode $ object ["message" .= ("Recommendation not found" :: Text)] }
        Just r  -> pure r

    currentStatus <- case textToStatus (_status rec) of
        Just s  -> pure s
        Nothing -> throwError err500 { errBody = encode $ object ["message" .= ("Invalid status in database" :: Text)] }

    activeStatus <- case currentStatus of
        Active s -> pure s
        Terminal _t -> throwError err409 { errBody = encode $ object ["message" .= ("Cannot apply event to terminal recommendation" :: Text)] }

    eventParse <- case textToEvent rawEvent of
        Just e -> pure e
        Nothing -> throwError err400 { errBody = encode $ object ["message" .= ("Invalid event" :: Text)] }

    newStatus <- case transition activeStatus eventParse of
        Right s -> pure s
        Left (InvalidTransition s e) -> throwError err409 { errBody = encode $ object ["message" .= ("Invalid transition" :: Text), "currentStatus" .= statusToText (Active s), "event" .= show e] }

    updatedRecs <- try $ runDb $ runUpdateReturningList $
        update (_recommendations appDb)
            (\r -> 
                (_status r <-. val_ (statusToText newStatus))
                <> (_toUserId r <-. just_ (val_ (auUserId authUser)))
            )
            (\r -> _recommendationId r ==. val_ recId
                &&. _status r ==. val_ (_status rec)
            )

    case updatedRecs of
        Left e@(SqlError { sqlState = state })
            | state == "23514" ->
                let jsonPayload = object ["message" .= ("Self-recommendation is not allowed." :: Text)]
                in throwError err409 { errBody = encode jsonPayload, errHeaders = [("Content-Type", "application/json")] }
            | otherwise         -> 
                let jsonPayload = object ["message" .= ("Internal database error" :: Text), "error" .= show e]
                in throwError err500 { errBody = encode jsonPayload, errHeaders = [("Content-Type", "application/json")] }

        Right (updatedRec:_) -> do
            let eventReq = CreateEventRecommendationRequest
                    { recommendationId = _recommendationId updatedRec
                    , status = _status updatedRec
                    }
            _ <- createEventRecommendation eventReq
            return $ toResponse updatedRec
        Right []             -> throwError err500 { errBody = "Failed to update recommendation" }
    where
        toResponse :: Recommendation -> RecommendationResponse
        toResponse dbRec = RecommendationResponse
            { recommendationId  = _recommendationId dbRec
            , fromUserId        = _fromUserId dbRec
            , toUserId          = _toUserId dbRec
            , mushroomId        = _mushroomId dbRec
            , status            = case textToStatus (_status dbRec) of
                                    Just s -> s
                                    Nothing -> Active Pending
            , note              = _note dbRec
            }

