{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DataKinds #-}

module Main (main) where

import Network.Wai.Handler.Warp (run)
import Network.Wai (Application, Request)
import Servant ( ServerT
    , (:<|>)(..)
    , Proxy(..)
    , Handler
    , hoistServerWithContext
    , serveWithContext
    )
import Servant.Server.Experimental.Auth (AuthHandler)
import Data.Pool (Pool, newPool, defaultPoolConfig, setNumStripes)
import Database.PostgreSQL.Simple (Connection, connectPostgreSQL, close)
import Control.Monad.Reader (runReaderT)
import API
import Users.Handlers (
    getUsers,
    createUser,
    deleteUser
    )
import Recommendations.Handler (createRecommendation, applyEvent)
import Types (AppM)
import Auth (authMiddleware, authContext, AuthenticatedUser)


server :: ServerT MainAPI AppM
server = (getUsers :<|> createUser :<|> deleteUser) :<|> (createRecommendation :<|> applyEvent)

nt :: Pool Connection -> AppM a -> Handler a
nt pool x = runReaderT x pool

authContextProxy :: Proxy '[AuthHandler Request AuthenticatedUser]
authContextProxy = Proxy

app :: Pool Connection -> Application
app pool = authMiddleware $ 
    serveWithContext api authContext (hoistServerWithContext api authContextProxy (nt pool) server)

main :: IO ()
main = do
    let config = setNumStripes (Just 10) $ defaultPoolConfig
                    (connectPostgreSQL "host=localhost dbname=mushroom user=admin password=password")
                    close
                    10.0
                    10

    pool <- newPool config

    run 8080 (app pool)

