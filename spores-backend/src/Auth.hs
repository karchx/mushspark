{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE FlexibleContexts #-}

module Auth
    ( AuthenticatedUser(..)
    , authMiddleware
    , authHandler
    , authContext
    ) where

import System.IO.Unsafe (unsafePerformIO)
import Data.UUID (UUID)
import qualified Data.UUID as UUID
import qualified Data.Vault.Lazy as Vault
import Network.Wai (Request, requestHeaders, vault, Middleware)
import Network.HTTP.Types (hAuthorization)
import Servant (throwError, err401, errBody, errHeaders, Context((:.), EmptyContext), AuthProtect)
import Servant.Server.Experimental.Auth (AuthHandler, mkAuthHandler, AuthServerData)
import qualified Web.JWT as JWT
import Data.ByteString (ByteString)
import qualified Data.ByteString.Char8 as BS
import Data.Text (Text)
import Data.Aeson (encode, object, (.=))
import qualified Data.Text.Encoding as TE
import qualified Data.Aeson as Aeson
import qualified Data.Map.Strict as Map

data AuthenticatedUser = AuthenticatedUser
    { auUserId :: UUID
    , auUserName :: Text
    } deriving (Show, Eq)

type instance AuthServerData (AuthProtect "Bearer") = AuthenticatedUser

authVaultKey :: Vault.Key AuthenticatedUser
authVaultKey = unsafePerformIO Vault.newKey
{-# NOINLINE authVaultKey #-}

jwtSecret :: JWT.EncodeSigner
jwtSecret = JWT.hmacSecret "spores-jwt-secret"

extractBearerToken :: Request -> Maybe ByteString
extractBearerToken req =
    case lookup hAuthorization (requestHeaders req) of
        Just authHeader
            | Just token <- BS.stripPrefix "Bearer " authHeader -> Just token
            | otherwise -> Nothing
        Nothing -> Nothing

validateToken :: ByteString -> Maybe AuthenticatedUser
validateToken token = do
    let tokenText = TE.decodeUtf8 token
    verifiedJWT <- JWT.decodeAndVerifySignature (JWT.toVerify jwtSecret) tokenText

    let claimsMap = JWT.unClaimsMap (JWT.unregisteredClaims (JWT.claims verifiedJWT))

    uidValue <- Map.lookup "user_id" claimsMap
    uidText <- case uidValue of
                Aeson.String t -> Just t
                _              -> Nothing
    uid <- UUID.fromText uidText
    let name = case Map.lookup "user_name" claimsMap of
                Just (Aeson.String t) -> t
                _                     -> "Unknown"
    return $ AuthenticatedUser uid name

authMiddleware :: Middleware
authMiddleware app req respond = do
    let maybeUser = extractBearerToken req >>= validateToken
        req' = case maybeUser of
            Just user -> req { vault = Vault.insert authVaultKey user (vault req) }
            Nothing   -> req
    app req' respond

authHandler :: AuthHandler Request AuthenticatedUser
authHandler = mkAuthHandler handler
  where
    jsonPayload = object ["message" .= ("Missing or invalid authentication token" :: Text)]
    handler req = case Vault.lookup authVaultKey (vault req) of
        Just user -> return user
        Nothing   -> throwError err401 { errBody = encode jsonPayload, errHeaders = [("Content-Type", "application/json")] }

authContext :: Context '[AuthHandler Request AuthenticatedUser]
authContext = authHandler :. EmptyContext

