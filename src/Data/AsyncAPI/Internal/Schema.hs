-- | The AsyncAPI 3.1.0 Schema Object: a superset of JSON Schema Draft 07
-- plus @discriminator@, @externalDocs@ and @deprecated@.
module Data.AsyncAPI.Internal.Schema
  ( Schema (..),
    SchemaObj (..),
    emptySchemaObj,
    JsonType (..),
    SchemaType (..),
    ItemsSchema (..),
    AdditionalProperties (..),
  )
where

import Control.Applicative ((<|>))
import Data.Aeson
  ( FromJSON (..),
    ToJSON (..),
    Value (..),
    withObject,
    withText,
    (.:?),
  )
import Data.AsyncAPI.Internal.Encoding
import Data.AsyncAPI.Internal.Referenced
import Data.AsyncAPI.Internal.Types
import Data.HashMap.Strict.InsOrd (InsOrdHashMap)
import Data.HashMap.Strict.InsOrd qualified as InsOrd
import Data.List.NonEmpty (NonEmpty)
import Data.Scientific (Scientific)
import Data.Text (Text)
import GHC.Generics (Generic)

-- | A JSON Schema type name.
--
-- [Schema Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#schemaObject)
data JsonType
  = JsonNull
  | JsonBoolean
  | JsonObject
  | JsonArray
  | JsonNumber
  | -- | Draft-07 @integer@ (subset of @number@).
    JsonInteger
  | JsonString
  deriving (Eq, Show, Generic)

instance ToJSON JsonType where
  toJSON = jsonViaEncoding
  toEncoding t = toEncoding (jsonTypeText t)

instance FromJSON JsonType where
  parseJSON = withText "JsonType" $ \t ->
    maybe (fail ("unknown JSON type: " <> show t)) pure (jsonTypeFromText t)

jsonTypeText :: JsonType -> Text
jsonTypeText = \case
  JsonNull -> "null"
  JsonBoolean -> "boolean"
  JsonObject -> "object"
  JsonArray -> "array"
  JsonNumber -> "number"
  JsonInteger -> "integer"
  JsonString -> "string"

jsonTypeFromText :: Text -> Maybe JsonType
jsonTypeFromText = \case
  "null" -> Just JsonNull
  "boolean" -> Just JsonBoolean
  "object" -> Just JsonObject
  "array" -> Just JsonArray
  "number" -> Just JsonNumber
  "integer" -> Just JsonInteger
  "string" -> Just JsonString
  _ -> Nothing

-- | The @type@ keyword: a single type or a union of types.
--
-- [Schema Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#schemaObject)
data SchemaType
  = -- | @type: string@ style.
    SingleType JsonType
  | -- | @type: [string, "null"]@ style.
    MultiType (NonEmpty JsonType)
  deriving (Eq, Show, Generic)

instance ToJSON SchemaType where
  toJSON = jsonViaEncoding
  toEncoding (SingleType t) = toEncoding t
  toEncoding (MultiType ts) = toEncoding ts

instance FromJSON SchemaType where
  parseJSON v = single <|> multi
    where
      single = SingleType <$> parseJSON v
      multi = MultiType <$> parseJSON v

-- | The @items@ keyword: one schema for all items, or per-position schemas.
--
-- [Schema Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#schemaObject)
data ItemsSchema
  = -- | A single schema applied to every item.
    SingleItem (Referenced Schema)
  | -- | A schema per tuple position.
    ItemList [Referenced Schema]
  deriving (Eq, Show, Generic)

instance ToJSON ItemsSchema where
  toJSON = jsonViaEncoding
  toEncoding (SingleItem s) = toEncoding s
  toEncoding (ItemList ss) = toEncoding ss

instance FromJSON ItemsSchema where
  parseJSON v = single <|> list
    where
      single = SingleItem <$> parseJSON v
      list = ItemList <$> parseJSON v

-- | @additionalProperties@ (and @additionalItems@): an on\/off flag or a
-- schema.
--
-- [Schema Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#schemaObject)
data AdditionalProperties
  = -- | @additionalProperties: false@ (or @true@).
    AllowAdditional Bool
  | -- | @additionalProperties: {schema}@.
    AdditionalSchema (Referenced Schema)
  deriving (Eq, Show, Generic)

instance ToJSON AdditionalProperties where
  toJSON = jsonViaEncoding
  toEncoding (AllowAdditional b) = toEncoding b
  toEncoding (AdditionalSchema s) = toEncoding s

instance FromJSON AdditionalProperties where
  parseJSON v = bool <|> schema
    where
      bool = AllowAdditional <$> parseJSON v
      schema = AdditionalSchema <$> parseJSON v

-- | A schema: either a JSON Schema boolean or a Schema Object. The empty
-- schema (allowing everything) is @BooleanSchema True@; a schema allowing
-- nothing is @BooleanSchema False@.
--
-- [AsyncAPI 3.1.0 — Schema Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#schemaObject)
data Schema
  = BooleanSchema Bool
  | SchemaObject SchemaObj
  deriving (Eq, Show, Generic)

instance ToJSON Schema where
  toJSON = jsonViaEncoding
  toEncoding (BooleanSchema b) = toEncoding b
  toEncoding (SchemaObject o) = toEncoding o

instance FromJSON Schema where
  parseJSON (Bool b) = pure (BooleanSchema b)
  parseJSON v = SchemaObject <$> parseJSON v

-- | A Schema Object with no keywords set.
emptySchemaObj :: SchemaObj
emptySchemaObj =
  SchemaObj
    { _schemaTitle = Nothing,
      _schemaType = Nothing,
      _schemaRequired = Nothing,
      _schemaMultipleOf = Nothing,
      _schemaMaximum = Nothing,
      _schemaExclusiveMaximum = Nothing,
      _schemaMinimum = Nothing,
      _schemaExclusiveMinimum = Nothing,
      _schemaMaxLength = Nothing,
      _schemaMinLength = Nothing,
      _schemaPattern = Nothing,
      _schemaMaxItems = Nothing,
      _schemaMinItems = Nothing,
      _schemaUniqueItems = Nothing,
      _schemaMaxProperties = Nothing,
      _schemaMinProperties = Nothing,
      _schemaEnum = Nothing,
      _schemaConst = Nothing,
      _schemaExamples = Nothing,
      _schemaIf = Nothing,
      _schemaThen = Nothing,
      _schemaElse = Nothing,
      _schemaReadOnly = Nothing,
      _schemaWriteOnly = Nothing,
      _schemaProperties = Nothing,
      _schemaPatternProperties = Nothing,
      _schemaAdditionalProperties = Nothing,
      _schemaAdditionalItems = Nothing,
      _schemaItems = Nothing,
      _schemaPropertyNames = Nothing,
      _schemaContains = Nothing,
      _schemaAllOf = Nothing,
      _schemaOneOf = Nothing,
      _schemaAnyOf = Nothing,
      _schemaNot = Nothing,
      _schemaDescription = Nothing,
      _schemaFormat = Nothing,
      _schemaDefault = Nothing,
      _schemaDiscriminator = Nothing,
      _schemaExternalDocs = Nothing,
      _schemaDeprecated = Nothing,
      _schemaExtensions = InsOrd.empty
    }

-- | The Schema Object record. Field order in 'ToJSON' follows the order the
-- keywords are listed in the specification's Properties section, with the
-- AsyncAPI-specific Fixed Fields (@discriminator@, @externalDocs@,
-- @deprecated@) at the end.
--
-- [AsyncAPI 3.1.0 — Schema Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#schemaObject)
data SchemaObj = SchemaObj
  { -- | @title@.
    -- [Schema Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#schemaObject)
    _schemaTitle :: Maybe Title,
    -- | @type@.
    _schemaType :: Maybe SchemaType,
    -- | @required@.
    _schemaRequired :: Maybe [Text],
    -- | @multipleOf@.
    _schemaMultipleOf :: Maybe Scientific,
    -- | @maximum@.
    _schemaMaximum :: Maybe Scientific,
    -- | @exclusiveMaximum@ (draft-07 numeric form).
    _schemaExclusiveMaximum :: Maybe Scientific,
    -- | @minimum@.
    _schemaMinimum :: Maybe Scientific,
    -- | @exclusiveMinimum@ (draft-07 numeric form).
    _schemaExclusiveMinimum :: Maybe Scientific,
    -- | @maxLength@.
    _schemaMaxLength :: Maybe Int,
    -- | @minLength@.
    _schemaMinLength :: Maybe Int,
    -- | @pattern@.
    _schemaPattern :: Maybe Text,
    -- | @maxItems@.
    _schemaMaxItems :: Maybe Int,
    -- | @minItems@.
    _schemaMinItems :: Maybe Int,
    -- | @uniqueItems@.
    _schemaUniqueItems :: Maybe Bool,
    -- | @maxProperties@.
    _schemaMaxProperties :: Maybe Int,
    -- | @minProperties@.
    _schemaMinProperties :: Maybe Int,
    -- | @enum@.
    _schemaEnum :: Maybe [Value],
    -- | @const@.
    _schemaConst :: Maybe Value,
    -- | @examples@.
    _schemaExamples :: Maybe [Value],
    -- | @if@.
    _schemaIf :: Maybe (Referenced Schema),
    -- | @then@.
    _schemaThen :: Maybe (Referenced Schema),
    -- | @else@.
    _schemaElse :: Maybe (Referenced Schema),
    -- | @readOnly@.
    _schemaReadOnly :: Maybe Bool,
    -- | @writeOnly@.
    _schemaWriteOnly :: Maybe Bool,
    -- | @properties@.
    _schemaProperties :: Maybe (InsOrdHashMap Text (Referenced Schema)),
    -- | @patternProperties@.
    _schemaPatternProperties :: Maybe (InsOrdHashMap Text (Referenced Schema)),
    -- | @additionalProperties@.
    _schemaAdditionalProperties :: Maybe AdditionalProperties,
    -- | @additionalItems@.
    _schemaAdditionalItems :: Maybe AdditionalProperties,
    -- | @items@.
    _schemaItems :: Maybe ItemsSchema,
    -- | @propertyNames@.
    _schemaPropertyNames :: Maybe (Referenced Schema),
    -- | @contains@.
    _schemaContains :: Maybe (Referenced Schema),
    -- | @allOf@.
    -- [Composition and Inheritance](https://www.asyncapi.com/docs/reference/specification/v3.1.0#schemaComposition)
    _schemaAllOf :: Maybe [Referenced Schema],
    -- | @oneOf@.
    _schemaOneOf :: Maybe [Referenced Schema],
    -- | @anyOf@.
    _schemaAnyOf :: Maybe [Referenced Schema],
    -- | @not@.
    _schemaNot :: Maybe (Referenced Schema),
    -- | @description@ (adjusted: CommonMark allowed).
    _schemaDescription :: Maybe Description,
    -- | @format@ (adjusted: see Data Type Formats).
    -- [Data Type Formats](https://www.asyncapi.com/docs/reference/specification/v3.1.0#dataTypeFormat)
    _schemaFormat :: Maybe Text,
    -- | @default@ (adjusted: MUST conform to the schema's type).
    _schemaDefault :: Maybe Value,
    -- | @discriminator@.
    -- [Schema Object, discriminator](https://www.asyncapi.com/docs/reference/specification/v3.1.0#schemaObjectDiscriminator)
    _schemaDiscriminator :: Maybe Text,
    -- | @externalDocs@.
    -- [Schema Object, externalDocs](https://www.asyncapi.com/docs/reference/specification/v3.1.0#schemaObjectExternalDocs)
    _schemaExternalDocs :: Maybe (Referenced ExternalDocumentation),
    -- | @deprecated@ (default @false@).
    -- [Schema Object, deprecated](https://www.asyncapi.com/docs/reference/specification/v3.1.0#schemaObjectDeprecated)
    _schemaDeprecated :: Maybe Bool,
    -- | Specification extensions (@x-@).
    _schemaExtensions :: InsOrdHashMap Text Value
  }
  deriving (Eq, Show, Generic)

instance ToJSON SchemaObj where
  toJSON = jsonViaEncoding
  toEncoding SchemaObj {..} =
    recordEncoding
      _schemaExtensions
      [ "title" .=? _schemaTitle,
        "type" .=? _schemaType,
        "required" .=? _schemaRequired,
        "multipleOf" .=? _schemaMultipleOf,
        "maximum" .=? _schemaMaximum,
        "exclusiveMaximum" .=? _schemaExclusiveMaximum,
        "minimum" .=? _schemaMinimum,
        "exclusiveMinimum" .=? _schemaExclusiveMinimum,
        "maxLength" .=? _schemaMaxLength,
        "minLength" .=? _schemaMinLength,
        "pattern" .=? _schemaPattern,
        "maxItems" .=? _schemaMaxItems,
        "minItems" .=? _schemaMinItems,
        "uniqueItems" .=? _schemaUniqueItems,
        "maxProperties" .=? _schemaMaxProperties,
        "minProperties" .=? _schemaMinProperties,
        "enum" .=? _schemaEnum,
        "const" .=? _schemaConst,
        "examples" .=? _schemaExamples,
        "if" .=? _schemaIf,
        "then" .=? _schemaThen,
        "else" .=? _schemaElse,
        "readOnly" .=? _schemaReadOnly,
        "writeOnly" .=? _schemaWriteOnly,
        "properties" .=? fmap SortedObject _schemaProperties,
        "patternProperties" .=? fmap SortedObject _schemaPatternProperties,
        "additionalProperties" .=? _schemaAdditionalProperties,
        "additionalItems" .=? _schemaAdditionalItems,
        "items" .=? _schemaItems,
        "propertyNames" .=? _schemaPropertyNames,
        "contains" .=? _schemaContains,
        "allOf" .=? _schemaAllOf,
        "oneOf" .=? _schemaOneOf,
        "anyOf" .=? _schemaAnyOf,
        "not" .=? _schemaNot,
        "description" .=? _schemaDescription,
        "format" .=? _schemaFormat,
        "default" .=? _schemaDefault,
        "discriminator" .=? _schemaDiscriminator,
        "externalDocs" .=? _schemaExternalDocs,
        "deprecated" .=? _schemaDeprecated
      ]

instance FromJSON SchemaObj where
  parseJSON = withObject "SchemaObj" $ \o -> do
    _schemaTitle <- o .:? "title"
    _schemaType <- o .:? "type"
    _schemaRequired <- o .:? "required"
    _schemaMultipleOf <- o .:? "multipleOf"
    _schemaMaximum <- o .:? "maximum"
    _schemaExclusiveMaximum <- o .:? "exclusiveMaximum"
    _schemaMinimum <- o .:? "minimum"
    _schemaExclusiveMinimum <- o .:? "exclusiveMinimum"
    _schemaMaxLength <- o .:? "maxLength"
    _schemaMinLength <- o .:? "minLength"
    _schemaPattern <- o .:? "pattern"
    _schemaMaxItems <- o .:? "maxItems"
    _schemaMinItems <- o .:? "minItems"
    _schemaUniqueItems <- o .:? "uniqueItems"
    _schemaMaxProperties <- o .:? "maxProperties"
    _schemaMinProperties <- o .:? "minProperties"
    _schemaEnum <- o .:? "enum"
    _schemaConst <- o .:? "const"
    _schemaExamples <- o .:? "examples"
    _schemaIf <- o .:? "if"
    _schemaThen <- o .:? "then"
    _schemaElse <- o .:? "else"
    _schemaReadOnly <- o .:? "readOnly"
    _schemaWriteOnly <- o .:? "writeOnly"
    _schemaProperties <- sortedMapField "properties" o
    _schemaPatternProperties <- sortedMapField "patternProperties" o
    _schemaAdditionalProperties <- o .:? "additionalProperties"
    _schemaAdditionalItems <- o .:? "additionalItems"
    _schemaItems <- o .:? "items"
    _schemaPropertyNames <- o .:? "propertyNames"
    _schemaContains <- o .:? "contains"
    _schemaAllOf <- o .:? "allOf"
    _schemaOneOf <- o .:? "oneOf"
    _schemaAnyOf <- o .:? "anyOf"
    _schemaNot <- o .:? "not"
    _schemaDescription <- o .:? "description"
    _schemaFormat <- o .:? "format"
    _schemaDefault <- o .:? "default"
    _schemaDiscriminator <- o .:? "discriminator"
    _schemaExternalDocs <- o .:? "externalDocs"
    _schemaDeprecated <- o .:? "deprecated"
    let _schemaExtensions = parseExtensions o
    pure SchemaObj {..}
