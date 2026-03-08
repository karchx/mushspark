{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module API where

import Servant
import DB (User)
import API.Users.Types (CreateUserRequest)
import Data.UUID (UUID)

type UserAPI = "users" :> Get '[JSON] [User]
        :<|> "users" :> ReqBody '[JSON] CreateUserRequest :> Post '[JSON] User
        :<|> "users" :> Capture "id" UUID :> Delete '[JSON] ()

api :: Proxy UserAPI
api = Proxy
