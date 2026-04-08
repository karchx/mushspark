{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module API 
    (MainAPI
    , api
    ) where

import Servant
import Users.DB (User)
import Mushrooms.DB (Mushroom)
import Users.Types (CreateUserRequest)
import Data.UUID (UUID)
import Recommendations.Types (CreateRecommendationRequest, RecommendationResponse, ApplyEvent)

type MainAPI = AdminAPI :<|> UserAPI :<|> RecommendationApi :<|> MushroomApi

type AdminAPI = "api" 
    :> "v1" 
    :> "admin" 
    :> "users" 
    :> QueryParam "limit" Integer
    :> QueryParam "offset" Integer
    :> Get '[JSON] [User]

type UserAPI = "users" :> ReqBody '[JSON] CreateUserRequest :> Post '[JSON] User
        :<|> "users" :> Capture "id" UUID :> Delete '[JSON] ()

type RecommendationApi =
    (AuthProtect "Bearer"
        :> "api"
        :> "v1"
        :> "recommendations"
        :> ReqBody '[JSON] CreateRecommendationRequest
        :> Post '[JSON] RecommendationResponse)
    :<|>
    (AuthProtect "Bearer"
        :> "api"
        :> "v1"
        :> "recommendations"
        :> "apply"
        :> ReqBody '[JSON] ApplyEvent
        :> Post '[JSON] RecommendationResponse)

type MushroomApi =
    "api"
    :> "v1"
    :> "mushrooms"
    :> QueryParam "limit" Integer
    :> QueryParam "offset" Integer
    :> Get '[JSON] [Mushroom]

api :: Proxy MainAPI
api = Proxy

