{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}

module Mushrooms.Handler 
    ( getMushroomPaginate
    ) where

import Database.Beam
import Types (AppM)
import Data.Maybe (fromMaybe)
import Mushrooms.DB 
    ( Mushroom
    , MushroomT(..)
    , AppDB(..)
    , appDb
     )
import DB (runDb)

getMushroomPaginate :: Maybe Integer -> Maybe Integer -> AppM [Mushroom]
getMushroomPaginate mLimit mOffset = do
    let limit = fromMaybe 10 mLimit
        offset = fromMaybe 0 mOffset

    getMushroom limit offset

getMushroom :: Integer -> Integer -> AppM [Mushroom]
getMushroom limit offset = runDb $ runSelectReturningList $ select $
    limit_ limit $
    offset_ offset $
    orderBy_ (\m -> asc_ (_mushroomId m)) $
    all_ (_mushroom appDb)

