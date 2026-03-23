{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module API 
    (MainAPI
    , api
    ) where

import Servant
import Users.DB (User)
import Users.Types (CreateUserRequest)
import Data.UUID (UUID)
import Recommendations.Types (CreateRecommendationRequest, RecommendationResponse, ApplyEvent)

type MainAPI = UserAPI :<|> RecommendationApi

type UserAPI = "users" :> Get '[JSON] [User]
        :<|> "users" :> ReqBody '[JSON] CreateUserRequest :> Post '[JSON] User
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
        :> Capture "id" UUID
        :> ReqBody '[JSON] ApplyEvent
        :> Post '[JSON] RecommendationResponse)

api :: Proxy MainAPI
api = Proxy

