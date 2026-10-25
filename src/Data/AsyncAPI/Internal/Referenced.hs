-- | Reference and simple shared metadata objects used across the model.
module Data.AsyncAPI.Internal.Referenced
  ( Reference (..),
    emptyReference,
    Referenced (..),
    ExternalDocumentation (..),
    emptyExternalDocumentation,
    Tags,
    Tag (..),
    emptyTag,
  )
where

import Data.Aeson (FromJSON (..), ToJSON (..), Value (..), withObject, (.:), (.:?))
import Data.Aeson.KeyMap qualified as KM
import Data.AsyncAPI.Internal.Encoding
import Data.AsyncAPI.Internal.Types
import Data.HashMap.Strict.InsOrd (InsOrdHashMap)
import Data.HashMap.Strict.InsOrd qualified as InsOrd
import Data.Text (Text)
import GHC.Generics (Generic)

-- | A reference to an external resource for extended documentation.
--
-- [AsyncAPI 3.1.0 — External Documentation Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#externalDocumentationObject)
data ExternalDocumentation = ExternalDocumentation
  { -- | A short description of the target documentation.
    _externalDocumentationDescription :: Maybe Description,
    -- | **REQUIRED.** The URL for the target documentation.
    _externalDocumentationUrl :: Url,
    -- | Specification extensions (@x-@).
    _externalDocumentationExtensions :: InsOrdHashMap Text Value
  }
  deriving (Eq, Show, Generic)

instance ToJSON ExternalDocumentation where
  toJSON = jsonViaEncoding
  toEncoding ExternalDocumentation {..} =
    recordEncoding
      _externalDocumentationExtensions
      [ "description" .=? _externalDocumentationDescription,
        "url" .=? Just _externalDocumentationUrl
      ]

instance FromJSON ExternalDocumentation where
  parseJSON = withObject "ExternalDocumentation" $ \o -> do
    _externalDocumentationDescription <- o .:? "description"
    _externalDocumentationUrl <- o .: "url"
    let _externalDocumentationExtensions = parseExtensions o
    pure ExternalDocumentation {..}

-- | An 'ExternalDocumentation' with only the required fields set.
emptyExternalDocumentation :: Url -> ExternalDocumentation
emptyExternalDocumentation u =
  ExternalDocumentation
    { _externalDocumentationDescription = Nothing,
      _externalDocumentationUrl = u,
      _externalDocumentationExtensions = InsOrd.empty
    }

-- | A simple object allowing referencing other components, internally and
-- externally. The 3.1 Reference Object defines exactly one field (@$ref@);
-- per the specification it cannot be extended and additional properties are
-- ignored.
--
-- [AsyncAPI 3.1.0 — Reference Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#referenceObject)
data Reference = Reference
  { -- | **REQUIRED.** The reference string.
    _reference :: Text
  }
  deriving (Eq, Show, Generic)

instance ToJSON Reference where
  toJSON = jsonViaEncoding
  toEncoding Reference {..} = recordEncoding InsOrd.empty ["$ref" .=? Just _reference]

instance FromJSON Reference where
  parseJSON = withObject "Reference" $ \o -> do
    _reference <- o .: "$ref"
    pure Reference {..}

-- | A 'Reference' with only the required fields set.
emptyReference :: Text -> Reference
emptyReference r =
  Reference
    { _reference = r
    }

-- | An inline definition or a 'Reference'.
--
-- Note: decoding peeks for a @$ref@ key, so an object carrying @$ref@ plus
-- sibling keywords (draft-07 allows @"$ref"@ next to @description@ etc.
-- inside Schema Objects) is silently narrowed to 'Ref' and the siblings are
-- dropped; sibling-keyword refs are not representable in this model.
--
-- [AsyncAPI 3.1.0 — Reference Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#referenceObject)
data Referenced a
  = -- | A definition written inline.
    Inline a
  | -- | A reference to a definition elsewhere.
    Ref Reference
  deriving (Eq, Show, Generic)

instance Functor Referenced where
  fmap f (Inline a) = Inline (f a)
  fmap _ (Ref r) = Ref r

instance Foldable Referenced where
  foldMap f (Inline a) = f a
  foldMap _ (Ref _) = mempty

instance Traversable Referenced where
  traverse f (Inline a) = Inline <$> f a
  traverse _ (Ref r) = pure (Ref r)

instance (ToJSON a) => ToJSON (Referenced a) where
  toJSON = jsonViaEncoding
  toEncoding (Inline a) = toEncoding a
  toEncoding (Ref r) = toEncoding r

instance (FromJSON a) => FromJSON (Referenced a) where
  parseJSON v@(Object o)
    | KM.member "$ref" o = Ref <$> parseJSON v
    | otherwise = Inline <$> parseJSON v
  parseJSON v = Inline <$> parseJSON v

-- $ metadata
--
-- [AsyncAPI 3.1.0 — Tags Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#tagsObject)

-- | A list of (possibly referenced) tags.
--
-- [AsyncAPI 3.1.0 — Tags Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#tagsObject)
type Tags = [Referenced Tag]

-- | Metadata attached to a single tag.
--
-- [AsyncAPI 3.1.0 — Tag Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#tagObject)
data Tag = Tag
  { -- | **REQUIRED.** The name of the tag.
    _tagName :: Name,
    -- | A short description for the tag.
    _tagDescription :: Maybe Description,
    -- | Additional external documentation for this tag.
    _tagExternalDocs :: Maybe (Referenced ExternalDocumentation),
    -- | Specification extensions (@x-@).
    _tagExtensions :: InsOrdHashMap Text Value
  }
  deriving (Eq, Show, Generic)

instance ToJSON Tag where
  toJSON = jsonViaEncoding
  toEncoding Tag {..} =
    recordEncoding
      _tagExtensions
      [ "name" .=? Just _tagName,
        "description" .=? _tagDescription,
        "externalDocs" .=? _tagExternalDocs
      ]

instance FromJSON Tag where
  parseJSON = withObject "Tag" $ \o -> do
    _tagName <- o .: "name"
    _tagDescription <- o .:? "description"
    _tagExternalDocs <- o .:? "externalDocs"
    let _tagExtensions = parseExtensions o
    pure Tag {..}

-- | A 'Tag' with only the required fields set.
emptyTag :: Name -> Tag
emptyTag n =
  Tag
    { _tagName = n,
      _tagDescription = Nothing,
      _tagExternalDocs = Nothing,
      _tagExtensions = InsOrd.empty
    }
