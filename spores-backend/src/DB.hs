module DB 
    (runDb
    ) where

import Control.Monad.Reader (ask)
import Database.Beam.Postgres (runBeamPostgres, Pg)
import Data.Pool (withResource)
import Types (AppM)

import Database.Beam (liftIO)

runDb :: Pg a -> AppM a
runDb query = do
    pool <- ask
    liftIO $ withResource pool $ \conn -> runBeamPostgres conn query

