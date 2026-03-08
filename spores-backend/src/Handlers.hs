{-# LANGUAGE OverloadedStrings #-}

module Handlers where

import Control.Monad.Reader (ask)
import Control.Monad.Catch (try)
import Servant (ServerT, (:<|>)(..), throwError, err409, err500, errBody, errHeaders)
import Data.Aeson (encode, object, (.=))
import Data.Text (Text)
import Database.Beam
import Database.Beam.Postgres (runBeamPostgres, Pg, SqlError(..))
import Database.Beam.Backend.SQL.BeamExtensions (runInsertReturningList)
import Data.Pool (withResource)
import API (UserAPI)
import Types (AppM)
import Data.UUID (UUID)
import DB
import API.Users.Types (CreateUserRequest(..))

runDb :: Pg a -> AppM a
runDb query = do
    pool <- ask
    liftIO $ withResource pool $ \conn -> runBeamPostgres conn query

getUsers :: AppM [User]
getUsers = runDb $ runSelectReturningList $ select $ all_ (_users appDb)

createUser :: CreateUserRequest -> AppM User
createUser req = do
    let insertQuery = insert (_users appDb) $
            insertExpressions
                [ User default_ (val_ (userName req)) (val_ (email req)) ]
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

server :: ServerT UserAPI AppM
server = getUsers :<|> createUser :<|> deleteUser

