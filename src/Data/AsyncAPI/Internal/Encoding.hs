-- | Ordered, omitting encoders shared by every AsyncAPI object.
--
-- Aeson's 'Data.Aeson.KeyMap.Object' is unordered, so every @ToJSON@ instance
-- in this library defines 'Data.Aeson.toEncoding' explicitly: fields are
-- emitted in the order of the specification's field tables, 'Nothing' fields
-- are omitted, and extension (@x-@) pairs follow the fixed fields in
-- 'InsOrdHashMap' order. This is what makes golden tests byte-stable.
module Data.AsyncAPI.Internal.Encoding
  ( recordEncoding,
    (.=?),
    SortedObject (..),
    extensionsSeries,
    parseExtensions,
    jsonViaEncoding,
    sortInsOrd,
    sortedMapField,
    escapeToken,
    unescapeToken,
  )
where

import Data.Aeson (FromJSON (..), ToJSON (..), Value, (.=))
import Data.Aeson qualified as Aeson
import Data.Aeson.Encoding (Encoding, dict, encodingToLazyByteString, pairs, text)
import Data.Aeson.Key (Key)
import Data.Aeson.Key qualified as Key
import Data.Aeson.KeyMap qualified as KM
import Data.Aeson.Types (Object, Parser, Series, withObject, (.:?))
import Data.Bifunctor (first)
import Data.HashMap.Strict qualified as HMS
import Data.HashMap.Strict.InsOrd (InsOrdHashMap)
import Data.HashMap.Strict.InsOrd qualified as InsOrd
import Data.List (sortOn)
import Data.Maybe (catMaybes)
import Data.Text (Text)
import Data.Text qualified as T

-- | Build an object 'Encoding': fixed-field series in the given (spec table)
-- order, omitting 'Nothing', followed by the @x-@ extension pairs.
recordEncoding :: InsOrdHashMap Text Value -> [Maybe Series] -> Encoding
recordEncoding exts fixed = pairs (mconcat (catMaybes (fixed ++ map Just (extensionsSeries exts))))

-- | Encode an optional field: 'Nothing' produces no series at all, so the
-- key is omitted from the object.
infixr 8 .=?

(.=?) :: (ToJSON a) => Key -> Maybe a -> Maybe Series
k .=? Just v = Just (k .= v)
_ .=? Nothing = Nothing

-- | Extension (@x-@) pairs in 'InsOrdHashMap' order.
extensionsSeries :: InsOrdHashMap Text Value -> [Series]
extensionsSeries = map (\(k, v) -> Key.fromText k .= v) . InsOrd.toList

-- | Collect the @x-@ extension keys from a parsed object, sorted by key
-- (aeson's 'Data.Aeson.KeyMap' loses source order; see the umbrella module).
parseExtensions :: Object -> InsOrdHashMap Text Value
parseExtensions =
  InsOrd.fromList
    . sortOn fst
    . map (first Key.toText)
    . filter (T.isPrefixOf "x-" . Key.toText . fst)
    . KM.toList

-- | Apply RFC 6901 token escaping (@~@ -> @~0@, @/@ -> @~1@).
escapeToken :: Text -> Text
escapeToken = T.replace "~" "~0" . T.replace "/" "~1"

-- | Undo RFC 6901 token escaping (~1 first, then ~0).
unescapeToken :: Text -> Text
unescapeToken = T.replace "~0" "~" . T.replace "~1" "/"

-- | Derive 'toJSON' from a type's ordered 'toEncoding'. Aeson's default
-- 'toJSON' goes through 'GHC.Generics' and loses the fixed-field order (and
-- mis-tags manual sum encodings), so every model instance defines
-- @toJSON = jsonViaEncoding@.
jsonViaEncoding :: (ToJSON a) => a -> Value
jsonViaEncoding a = case Aeson.eitherDecode' (encodingToLazyByteString (toEncoding a)) of
  Right v -> v
  Left e -> error ("jsonViaEncoding: impossible decode failure: " <> e)

-- | JSON-boundary newtype: encodes/decodes an 'InsOrdHashMap Text v' as a JSON
-- object (encode order = insertion order), independent of
-- insert-ordered-containers' own aeson instances (0.3.x emits pair arrays).
--
-- Decode deliberately does NOT sort: it reproduces 0.2.7's behavior
-- (insertion order = hash order of the key set) so fragment goldens stay
-- byte-identical; document-level sorting lives in 'sortedMapField'.
newtype SortedObject v = SortedObject {unSortedObject :: InsOrdHashMap Text v}
  deriving newtype (Eq, Show)

instance (ToJSON v) => ToJSON (SortedObject v) where
  toJSON = jsonViaEncoding
  toEncoding (SortedObject m) =
    dict text toEncoding InsOrd.foldrWithKey m

instance (FromJSON v) => FromJSON (SortedObject v) where
  -- 0.2.7's FromJSON1 decodes through a plain 'HashMap' and converts with
  -- 'fromList . HashMap.toList', so the insertion order (and hence the
  -- reencoded order) is the hash order of the key set, not the JSON source
  -- order and not aeson's KeyMap iteration order. Reproduce exactly.
  parseJSON = withObject "map" $ \o ->
    SortedObject . InsOrd.fromList . HMS.toList . HMS.fromList
      <$> traverse (\(k, v) -> (,) (Key.toText k) <$> parseJSON v) (KM.toList o)

-- | Sort a decoded map by key (aeson's key-map loses source order; see the
-- umbrella module for the roundtrip contract).
sortInsOrd :: InsOrdHashMap Text a -> InsOrdHashMap Text a
sortInsOrd = InsOrd.fromList . sortOn fst . InsOrd.toList

-- | Decode an optional object-valued field as a key-sorted 'InsOrdHashMap'.
sortedMapField :: (FromJSON a) => Key -> Object -> Parser (Maybe (InsOrdHashMap Text a))
sortedMapField k o = fmap (sortInsOrd . unSortedObject) <$> o .:? k
