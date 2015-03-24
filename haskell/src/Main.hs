{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ExtendedDefaultRules #-}

import qualified Database.MongoDB as Mongo
import qualified Data.Aeson as A
import Network.HTTP.Server
import Network.HTTP.Server.Logger
import Network.URL as URL hiding (host)
import Codec.Binary.UTF8.String
import Data.AesonBson (aesonify)
import Data.List (isPrefixOf)
import Data.Maybe (fromMaybe)

-- import Network.HTTP.Server.HtmlForm as Form
-- import Text.JSON
-- import Text.JSON.String (runGetJSON)
-- import Text.XHtml hiding (URL, select)
-- import Control.Exception (try, SomeException)
-- import System.FilePath
{-- MAIN ---------------------------------------------------------------------}

type ServerConfig = Config
data AppConfig = AppConfig { db :: Mongo.Database
                           , coll :: Mongo.Collection
                           , address :: String
                           , token :: String }

serverConfig :: ServerConfig
serverConfig = defaultConfig { srvLog = stdLogger, srvPort = 8080 }

appConfig :: AppConfig
appConfig = AppConfig { db = "slackbot"
                      , coll = "testData"
                      , address = "127.0.0.1"
                      , token = "m3ABP8zIiY5wzJAtuJcwffji" }

access :: Mongo.Pipe -> Mongo.Action IO a -> IO a
access conn action = Mongo.access conn Mongo.master (db appConfig) action

main :: IO ()
main = serverWith serverConfig mainHandler

mainHandler :: Handler String
mainHandler _ url rq = do
  conn <- Mongo.connect (Mongo.host (address appConfig))
  case rqMethod rq of
    GET  -> handleGet url conn
    POST -> handlePost url rq conn
    _    -> return badRequest

{-- GET ----------------------------------------------------------------------}

handleGet :: URL -> Mongo.Pipe -> IO (Response String)
handleGet url conn = do
-- validate route
  case url_path url of
-- return all data from the database as JSON
    "" -> access conn $ getAllLinks >>= stringifyJSON
    _  -> return notFound

getAllLinks :: Mongo.Action IO [Mongo.Document]
getAllLinks = Mongo.rest =<< Mongo.find (Mongo.select [] (coll appConfig))

stringifyJSON :: [Mongo.Document] -> Mongo.Action IO (Response String)
stringifyJSON = return . sendJSON OK . show . map (A.encode . aesonify)

{-- POST ---------------------------------------------------------------------}
handlePost :: URL -> Request String -> Mongo.Pipe -> IO (Response String)
handlePost url rq conn =
-- validate route
  case url_path url of
    "api/v1/links" -> handleLinksV1 rq conn
    _ -> return notFound

handleLinksV1 :: Request String -> Mongo.Pipe -> IO (Response String)
handleLinksV1 rq conn = case findHeader HdrContentType rq of
  Just ty | "application/x-www-form-urlencoded" `isPrefixOf` ty ->
    if token' /= (token appConfig)
    then return unauthorized
    else
      if null link
      then return msgError
      else do
        access conn $ Mongo.insert (coll appConfig) ["text" Mongo.=: link]
        return msgOk
    where
      ps  = URL.importParams . decodeString $ rqBody rq
      extract = flip lookup $ fromMaybe [] ps
      token' = fromMaybe "" $ extract "token"
      username = fromMaybe "user" $ extract "user_name"
      link = fromMaybe "" $ do
        trw <- extract "trigger_word"
        txt <- extract "text"
        return $ drop (1 + length trw) txt
      msgOk = sendText OK $
        "Yes, " ++ username ++ "! Link: " ++ link ++ " was saved"
      msgError = sendText BadRequest $
        "error: you can't save empty links, " ++ username
  _ -> return badRequest

sendText :: StatusCode -> String -> Response String
sendText s v  = insertHeader HdrContentLength (show (length txt))
              $ insertHeader HdrContentEncoding "UTF-8"
              $ insertHeader HdrContentEncoding "text/plain"
              $ (respond s :: Response String) { rspBody = txt }
              where txt = encodeString v

badRequest :: Response String
badRequest = sendText BadRequest "Bad Request"

notFound :: Response String
notFound = sendText NotFound "404 Nothing"

unauthorized :: Response String
unauthorized = sendText Unauthorized "Unauthorized request"

sendJSON :: StatusCode -> String -> Response String
sendJSON s v = insertHeader HdrContentType "application/json"
             $ sendText s v

--
-- sendHTML       :: StatusCode -> Html -> Response String
-- sendHTML s v    = insertHeader HdrContentType "text/html"
--                 $ sendText s (renderHtml v)
--
-- sendScript     :: StatusCode -> String -> Response String
-- sendScript s v  = insertHeader HdrContentType "application/x-javascript"
--                 $ sendText s v

