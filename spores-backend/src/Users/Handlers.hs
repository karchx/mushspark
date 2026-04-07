{-# LANGUAGE OverloadedStrings #-}

module Users.Handlers 
    ( getUsers
    , createUser
    , deleteUser
    ) where

import Control.Monad.Catch (try)
import Servant (throwError, err409, err500, errBody, errHeaders)
import Data.Aeson (encode, object, (.=))
import Data.Text (Text)
import Database.Beam
import Database.Beam.Postgres (SqlError(..))
import Database.Beam.Backend.SQL.BeamExtensions (runInsertReturningList)
import Types (AppM)
import Data.UUID (UUID)
import Data.Password.Argon2 (mkPassword, hashPassword, PasswordHash (unPasswordHash))

import Users.DB
import Users.Types (CreateUserRequest(..))
import DB (runDb)

getUsers :: AppM [User]
getUsers = runDb $ runSelectReturningList $ select $ all_ (_users appDb)

createUser :: CreateUserRequest -> AppM User
createUser req = do
    passHashObj <- liftIO $ hashPassword (mkPassword (password req))
    let hashedPass = unPasswordHash passHashObj

    let insertQuery = insert (_users appDb) $
            insertExpressions
                [ User default_ (val_ (userName req)) (val_ (email req)) (val_ hashedPass)]
    insertedUsers <- try $ runDb $ runInsertReturningList insertQuery

    case insertedUsers of
        Left (SqlError { sqlState = state })
            | state == "23505" ->
                let jsonPayload = object ["message" .= ("Email already exists" :: Text)]
                in throwError err409 { errBody = encode jsonPayload, errHeaders = [("Content-Type", "application/json")] }
            | otherwise       -> throwError err500 { errBody = "Internal database error: " }
        Right (newUser:_) -> return newUser
        Right []          -> throwError err500 { errBody = "Failed to create user" }

deleteUser :: UUID -> AppM ()
deleteUser uid = runDb $ runDelete $ delete (_users appDb) (\u -> _userId u ==. val_ uid)

