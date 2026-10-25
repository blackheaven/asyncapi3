-- | Structural validation of AsyncAPI 3.1.0 documents.
module Data.AsyncAPI.Validation
  ( ValidationError (..),
    ValidationRule (..),
    validateAsyncAPI,
    supportedSchemaFormats,
    validVersion,
    internalRefs,
    resolvesRef,
    multiFormatSchemas,
  )
where

import Data.Aeson (Value (..), toJSON)
import Data.Aeson.Key qualified as Key
import Data.Aeson.KeyMap qualified as KM
import Data.AsyncAPI.Internal
import Data.Text (Text)
import Data.Text qualified as T
import Data.Vector qualified as V

-- | The rule a 'ValidationError' came from.
data ValidationRule
  = -- | The @asyncapi@ version string.
    VersionRule
  | -- | Internal @$ref@ resolution.
    RefResolutionRule
  | -- | Multi Format Schema @schemaFormat@ support (MUST table only).
    SchemaFormatRule
  deriving (Eq, Show)

-- | A single structural validation failure. The pointer is an RFC 6901 JSON
-- pointer into the document (@\"\"@ = root).
data ValidationError = ValidationError
  { -- | Rule that produced the failure.
    validationRule :: ValidationRule,
    -- | Pointer to the offending location.
    validationPointer :: Text,
    -- | Human-readable description of the failure.
    validationMessage :: Text
  }
  deriving (Eq, Show)

-- | Schema formats every implementation MUST support
-- ([Schema formats table](https://www.asyncapi.com/docs/reference/specification/v3.1.0#multiFormatSchemaFormatTable)).
supportedSchemaFormats :: [Text]
supportedSchemaFormats =
  [ "application/vnd.aai.asyncapi;version=3.1.0",
    "application/vnd.aai.asyncapi+json;version=3.1.0",
    "application/vnd.aai.asyncapi+yaml;version=3.1.0",
    "application/schema+json;version=draft-07",
    "application/schema+yaml;version=draft-07"
  ]

-- | Structural rules: version string, internal reference resolution, and
-- Multi Format Schema 'supportedSchemaFormats'. Result order is unspecified.
validateAsyncAPI :: AsyncAPI -> [ValidationError]
validateAsyncAPI doc = versionErrors <> refErrors <> schemaFormatErrors
  where
    json = toJSON doc
    versionErrors =
      [ ValidationError VersionRule "" ("unsupported asyncapi version: " <> v)
      | let v = getVersion (_asyncAPIAsyncAPI doc),
        not (validVersion v)
      ]
    refErrors =
      [ ValidationError RefResolutionRule p ("unresolved internal reference: " <> r)
      | (p, r) <- internalRefs json,
        not (resolvesRef r json)
      ]
    schemaFormatErrors =
      [ ValidationError SchemaFormatRule p ("unsupported schemaFormat: " <> f)
      | (p, f) <- multiFormatSchemas json,
        f `notElem` supportedSchemaFormats
      ]

-- | The @asyncapi@ version string must be @3.<digits>.<digits>(-suffix)?@.
validVersion :: Text -> Bool
validVersion v = case T.splitOn "." v of
  ["3", mi, pa] ->
    digits mi
      && let (pre, post) = T.breakOn "-" pa
          in digits pre && (T.null post || (T.length post > 1))
  _ -> False
  where
    digits t = not (T.null t) && T.all (\c -> c >= '0' && c <= '9') t

-- | All internal @$ref@ values (@#/@-prefixed) with their RFC 6901 pointers.
internalRefs :: Value -> [(Text, Text)]
internalRefs = go ""
  where
    go p (Object o) =
      concatMap
        ( \(k, v) ->
            case (Key.toText k, v) of
              ("$ref", String r)
                | "#/" `T.isPrefixOf` r -> [(p, r)]
              _ -> go (child p k) v
        )
        (KM.toList o)
    go p (Array a) =
      concat
        [go (p <> "/" <> T.pack (show i)) v | (i, v) <- zip [0 :: Int ..] (V.toList a)]
    go _ _ = []
    child p k = p <> "/" <> escapeToken (Key.toText k)

-- | Whether an internal reference (@#\/a\/b@) resolves in the document.
resolvesRef :: Text -> Value -> Bool
resolvesRef r doc = case T.stripPrefix "#/" r of
  Nothing -> False
  Just rest -> go (T.splitOn "/" rest) doc
  where
    go [] _ = True
    go (t : ts) v = case v of
      Object o -> case KM.lookup (Key.fromText (unescapeToken t)) o of
        Just v' -> go ts v'
        Nothing -> False
      _ -> False

-- | All @schemaFormat@ values of embedded Multi Format Schema Objects
-- (objects carrying both @schemaFormat@ and @schema@ keys), with pointers.
multiFormatSchemas :: Value -> [(Text, Text)]
multiFormatSchemas = go ""
  where
    go p (Object o)
      | Just (String f) <- KM.lookup "schemaFormat" o,
        KM.member "schema" o =
          (p, f) : concatMap (go p . snd) (KM.toList o)
      | otherwise = concatMap (go p . snd) (KM.toList o)
    go p (Array a) = concatMap (go p) (V.toList a)
    go _ _ = []
