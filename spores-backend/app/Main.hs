{-# LANGUAGE OverloadedStrings #-}
module Main (main) where

import Network.Wai.Handler.Warp (run)
import Servant
import Data.Pool (Pool, newPool, defaultPoolConfig, setNumStripes)
import Database.PostgreSQL.Simple (Connection, connectPostgreSQL, close)
import Control.Monad.Reader (runReaderT)
import API
import Handlers
import Types (AppM)

nt :: Pool Connection -> AppM a -> Handler a
nt pool x = runReaderT x pool

app :: Pool Connection -> Application
app pool = serve api (hoistServer api (nt pool) server)

main :: IO ()
main = do
    let config = setNumStripes (Just 10) $ defaultPoolConfig
                    (connectPostgreSQL "host=localhost dbname=mushroom user=admin password=password")
                    close
                    10.0
                    10

    pool <- newPool config

    run 8080 (app pool)

