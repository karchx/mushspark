{-# LANGUAGE GeneralizedNewtypeDeriving #-}

module Types (
    AppM
) where

import Control.Monad.Reader (ReaderT)
import Servant (Handler)
import Data.Pool (Pool)
import Database.PostgreSQL.Simple (Connection)

type AppM = ReaderT (Pool Connection) Handler
