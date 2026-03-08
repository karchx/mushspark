{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}

module API.Users.Types (CreateUserRequest(..)) where

import GHC.Generics (Generic)
import Data.Aeson (ToJSON, FromJSON)
import Data.Text (Text)

data CreateUserRequest = CreateUserRequest
    { userName :: Text
    , email :: Text 
    } deriving (Generic)

instance FromJSON CreateUserRequest

instance ToJSON CreateUserRequest

