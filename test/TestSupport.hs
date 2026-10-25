-- | Shared test infrastructure: extraction of examples embedded in the
-- vendored specification, RFC 7386 merge-patch, RFC 6901 JSON pointers, and
-- file loaders.
module TestSupport
  ( ExampleBlock (..),
    annotatedExamples,
    allFencedBlocks,
    specMarkdownPath,
    baseDocPath,
    examplesDir,
    exampleFiles,
    projectRoot,
    loadSpecMarkdown,
    loadBaseDoc,
    parseYamlFile,
    mergePatch,
    pointerGet,
    pointerSet,
    unescapeToken,
    escapeToken,
    splitPointer,
    Target (..),
    pointerType,
    TestSupport.failWith,
    pendWith,
    byteGolden,
  )
where

import Data.Aeson (FromJSON, ToJSON, Value (..), parseJSON)
import Data.Aeson qualified as Aeson
import Data.Aeson.Key qualified as Key
import Data.Aeson.KeyMap qualified as KM
import Data.Aeson.Types (Parser)
import Data.AsyncAPI.Internal
import Data.ByteString (ByteString)
import Data.ByteString qualified as BS
import Data.ByteString.Lazy qualified as BL
import Data.List (isSuffixOf, sort)
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.Encoding (decodeUtf8, encodeUtf8)
import Data.Vector qualified as V
import Data.Yaml qualified (decodeEither')
import System.Directory
  ( doesDirectoryExist,
    doesFileExist,
    getCurrentDirectory,
    listDirectory,
  )
import System.FilePath (splitDirectories, (</>))
import Test.Hspec (expectationFailure, pendingWith)
import Test.Hspec.Golden (Golden (..))

-- | A fenced code block extracted from the spec markdown.
data ExampleBlock = ExampleBlock
  { -- | 1-based line number of the opening fence.
    blockLine :: Int,
    -- | Fence language (@yaml@, @json@, @text@, ...).
    blockFormat :: Text,
    -- | Block body (between the fences).
    blockBody :: Text,
    -- | For annotated blocks: the tester @name@ field.
    blockName :: Maybe Text,
    -- | For annotated blocks: the tester @json_pointer@ field (@""@ = root).
    blockPointer :: Maybe Text
  }
  deriving (Eq, Show)

-- | Path of the vendored spec markdown, relative to the project root.
specMarkdownPath :: FilePath
specMarkdownPath = "reference/asyncapi.md"

-- | Path of the (patched) base document, relative to the project root.
baseDocPath :: FilePath
baseDocPath = "reference/base-doc.json"

-- | Directory of real-world example documents, relative to the project root.
examplesDir :: FilePath
examplesDir = "reference/examples"

-- | The project root: the nearest ancestor of the current directory that
-- contains the vendored spec. @cabal test@ runs with the package root as cwd,
-- so this normally resolves immediately.
projectRoot :: IO FilePath
projectRoot = do
  cwd <- getCurrentDirectory
  go (splitDirectories cwd)
  where
    go [] = fail ("project root not found (missing " <> specMarkdownPath <> ")")
    go dirs = do
      let cand = if null dirs then "/" else foldr (</>) "" dirs
      ok <- doesFileExist (cand </> specMarkdownPath)
      if ok then pure cand else go (init dirs)

-- | Every example document under 'examplesDir' (sorted), as project-relative
-- paths.
exampleFiles :: IO [FilePath]
exampleFiles = do
  root <- projectRoot
  let go d = do
        entries <- listDirectory (root </> d)
        concat
          <$> mapM
            ( \e -> do
                let rel = d </> e
                isDir <- doesDirectoryExist (root </> rel)
                if isDir
                  then go rel
                  else pure [rel | any (`isSuffixOf` e) [".yml", ".yaml"]]
            )
            entries
  sort <$> go examplesDir

-- | Read the vendored spec markdown.
loadSpecMarkdown :: IO Text
loadSpecMarkdown = do
  root <- projectRoot
  decodeUtf8 <$> readBs (root </> specMarkdownPath)

-- | Read and parse the base document used by the spec's own example tester.
loadBaseDoc :: IO Value
loadBaseDoc = do
  root <- projectRoot
  bs <- readBs (root </> baseDocPath)
  either (fail . ("base-doc.json: " <>)) pure (Aeson.eitherDecode (BL.fromStrict bs))

-- | Parse a YAML file into an aeson 'Value' (mappings become key-maps).
parseYamlFile :: FilePath -> IO Value
parseYamlFile path = do
  bs <- readBs path
  either (fail . ((path <> ": ") <>) . show) pure (Data.Yaml.decodeEither' bs)

readBs :: FilePath -> IO ByteString
readBs p = BL.toStrict <$> BL.readFile p

-- | Extract all fenced blocks. A block is tester-annotated iff the line
-- immediately above its opening fence matches
-- @<!-- asyncapi-example-tester:{...} -->@.
allFencedBlocks :: Text -> [ExampleBlock]
allFencedBlocks md = go (zip [1 ..] (T.lines md)) Nothing
  where
    go [] _ = []
    go ((n, l) : rest) pending
      | Just ann <- annotationOf l = go rest (Just ann)
      | Just lang <- openFence l =
          let (bodyLines, rest') = break (isClose . snd) rest
              (name, pointer) = case pending of
                Just ann -> (strField "name" ann, strField "json_pointer" ann)
                Nothing -> (Nothing, Nothing)
           in ExampleBlock
                n
                lang
                (T.intercalate "\n" (map snd bodyLines))
                name
                pointer
                : go (drop 1 rest') Nothing
      | otherwise = go rest Nothing
    openFence l =
      let t = T.strip l
       in if "```" `T.isPrefixOf` t then Just (T.strip (T.drop 3 t)) else Nothing
    isClose l = T.strip l == "```"

-- | Tester-annotated examples only.
annotatedExamples :: Text -> [ExampleBlock]
annotatedExamples = filter (maybe False (const True) . blockPointer) . allFencedBlocks

annotationOf :: Text -> Maybe Value
annotationOf l = do
  t <- T.stripPrefix "<!-- asyncapi-example-tester:" (T.strip l)
  json <- T.stripSuffix "-->" t
  either (const Nothing) Just (Aeson.eitherDecode (BL.fromStrict (encodeUtf8 json)))

strField :: Text -> Value -> Maybe Text
strField k (Object o) = case KM.lookup (Key.fromText k) o of
  Just (String s) -> Just s
  _ -> Nothing
strField _ _ = Nothing

-- $ pointers
--
-- RFC 6901 JSON Pointer helpers. Tokens are escaped with @~1@ for @/@ and
-- @~0@ for @~@.

-- | Split a pointer like @\/info\/contact@ into unescaped tokens.
-- @""@ is the empty pointer (the whole document).
splitPointer :: Text -> [Text]
splitPointer "" = []
splitPointer p = map unescapeToken (drop 1 (T.splitOn "/" p))

-- | RFC 7386 merge-patch: @target@ patched with @patch@.
mergePatch :: Value -> Value -> Value
mergePatch target patch = case (target, patch) of
  (_, Object po) ->
    Object
      ( foldr
          ( \(k, v) acc -> case v of
              Null -> KM.delete (Key.fromText k) acc
              _ ->
                KM.insert
                  (Key.fromText k)
                  (mergePatch (lookupOr k acc Null) v)
                  acc
          )
          (emptyOrObject target)
          (map (fmap' Key.toText) (KM.toList po))
      )
  (_, p) -> p
  where
    fmap' f (a, b) = (f a, b)
    emptyOrObject (Object o) = o
    emptyOrObject _ = KM.empty
    lookupOr k o d = maybe d id (KM.lookup (Key.fromText k) o)

-- | Look up a pointer in a value ('Nothing' when the path does not exist).
pointerGet :: [Text] -> Value -> Maybe Value
pointerGet [] v = Just v
pointerGet (t : ts) v = case v of
  Object o -> KM.lookup (Key.fromText t) o >>= pointerGet ts
  Array a
    | Just i <- readIndex t,
      i < V.length a ->
        pointerGet ts (a V.! i)
  _ -> Nothing

-- | Set (or remove with 'Nothing') the value at a pointer, creating missing
-- intermediate containers. Numeric segments create\/extend JSON arrays
-- (padded with 'Null'), matching the spec tester's @_.set@ behavior; a
-- non-container at an intermediate position is replaced, like lodash.
pointerSet :: [Text] -> Maybe Value -> Value -> Value
pointerSet [] mv _ = maybe Null id mv
pointerSet (t : ts) mv v
  | Just i <- readIndex t =
      case v of
        Array a
          | i < V.length a -> Array (a V.// [(i, sub)])
          | otherwise -> Array (a V.++ V.replicate (i - V.length a) Null V.++ V.singleton sub)
        _ -> Array (V.replicate i Null V.++ V.singleton sub)
  | otherwise = case v of
      Object o -> Object (KM.insert (Key.fromText t) sub o)
      _ -> Object (KM.singleton (Key.fromText t) sub)
  where
    sub = case existing of
      Just existing' -> pointerSet ts mv existing'
      Nothing -> pointerSet ts mv Null
    existing = case v of
      Object o -> KM.lookup (Key.fromText t) o
      Array a
        | Just i <- readIndex t,
          i < V.length a ->
            Just (a V.! i)
      _ -> Nothing

-- | RFC 6901 array index: digits only, no leading zeros (except "0"),
-- bounded to avoid absurd 'read' results.
readIndex :: Text -> Maybe Int
readIndex t
  | t == "0" = Just 0
  | not (T.null t),
    T.all (\c -> c >= '1' && c <= '9') t,
    T.length t <= 9 =
      Just (read (T.unpack t))
  | otherwise = Nothing

-- | A model type an example fragment can be decoded into, carrying the
-- dictionaries the golden test needs.
data Target
  = forall a.
  (ToJSON a, FromJSON a, Eq a, Show a) =>
  Target
  { -- | Human-readable name of the target type.
    targetName :: String,
    -- | Parser from a JSON 'Value' to the target type.
    targetParser :: Value -> Parser a
  }

-- | Map an example @json_pointer@ to the model type the fragment is decoded
-- into. Every pointer used by an annotated example must have an explicit row;
-- a missing row fails the test, naming the pointer.
pointerType :: Text -> Maybe Target
pointerType ptr = case splitPointer ptr of
  [] -> Just (Target "AsyncAPI" (parseJSON :: Value -> Parser AsyncAPI))
  ["info"] -> Just (Target "Info" (parseJSON :: Value -> Parser Info))
  ["info", "contact"] -> Just (Target "Contact" (parseJSON :: Value -> Parser Contact))
  ["info", "license"] -> Just (Target "License" (parseJSON :: Value -> Parser License))
  ["servers"] -> Just (Target "Servers" (parseJSON :: Value -> Parser (SortedObject (Referenced Server))))
  ["servers", _] -> Just (Target "Server" (parseJSON :: Value -> Parser Server))
  ["channels"] -> Just (Target "Channels" (parseJSON :: Value -> Parser (SortedObject (Referenced Channel))))
  ["channels", _] -> Just (Target "Channel" (parseJSON :: Value -> Parser Channel))
  ["components", "tags", _] -> Just (Target "Tag" (parseJSON :: Value -> Parser Tag))
  ["components", "externalDocs", _] -> Just (Target "ExternalDocumentation" (parseJSON :: Value -> Parser ExternalDocumentation))
  ["components", "securitySchemes", _, "flows", _] -> Just (Target "OAuthFlow" (parseJSON :: Value -> Parser OAuthFlow))
  ["components", "securitySchemes", _] -> Just (Target "SecurityScheme" (parseJSON :: Value -> Parser SecurityScheme))
  ["channels", _, "messages"] -> Just (Target "Messages" (parseJSON :: Value -> Parser (SortedObject (Referenced Message))))
  ["operations"] -> Just (Target "Operations" (parseJSON :: Value -> Parser (SortedObject (Referenced Operation))))
  ["operations", _] -> Just (Target "Operation" (parseJSON :: Value -> Parser Operation))
  ["operations", _, "reply", "address"] -> Just (Target "OperationReplyAddress" (parseJSON :: Value -> Parser OperationReplyAddress))
  ["operations", _, "traits", _] -> Just (Target "OperationTrait" (parseJSON :: Value -> Parser OperationTrait))
  ["components", "schemas", _] -> Just (Target "SchemaDefinition" (parseJSON :: Value -> Parser SchemaDefinition))
  ["components", "messages", _, "examples", _] -> Just (Target "MessageExample" (parseJSON :: Value -> Parser MessageExample))
  ["components", "messages", _, "payload"] -> Just (Target "SchemaDefinition" (parseJSON :: Value -> Parser SchemaDefinition))
  ["components", "messages", _] -> Just (Target "Message" (parseJSON :: Value -> Parser Message))
  ["components", "messageTraits", _] -> Just (Target "MessageTrait" (parseJSON :: Value -> Parser MessageTrait))
  ["components", "correlationIds", _] -> Just (Target "CorrelationId" (parseJSON :: Value -> Parser CorrelationId))
  _ -> Nothing

-- | Fail the enclosing golden example ('expectationFailure' throws, so the
-- unreachable continuation is never evaluated).
failWith :: String -> IO (Golden BS.ByteString)
failWith msg = expectationFailure msg >> pure (error "expectationFailure should have thrown")

-- | Mark the golden example pending ('pendingWith' throws; see 'failWith').
pendWith :: String -> IO (Golden BS.ByteString)
pendWith msg = pendingWith msg >> pure (error "pendingWith should have thrown")

-- | Byte-exact golden comparison against @test/golden/<path>@.
byteGolden :: FilePath -> BS.ByteString -> Golden BS.ByteString
byteGolden path out =
  Golden
    { output = out,
      encodePretty = T.unpack . decodeUtf8,
      writeToFile = BS.writeFile,
      readFromFile = BS.readFile,
      goldenFile = "test/golden" </> path,
      actualFile = Nothing,
      failFirstTime = False
    }
