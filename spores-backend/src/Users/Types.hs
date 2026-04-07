{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}

module Users.Types (CreateUserRequest(..)) where

import GHC.Generics (Generic)
import Data.Aeson (ToJSON, FromJSON)
import Data.Text (Text)

data CreateUserRequest = CreateUserRequest
    { userName :: Text
    , email :: Text 
    , password :: Text
    } deriving (Generic)

instance FromJSON CreateUserRequest

instance ToJSON CreateUserRequest

data LoginResponse = LoginResponse
    { token :: Text
    } deriving (Generic)

