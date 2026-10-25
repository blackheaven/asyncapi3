-- | Golden tests for the examples embedded in the specification. Each
-- tester-annotated block is decoded into the model type named by its
-- @json_pointer@ (see 'pointerType'), encoded with the library's ordered
-- encoder, and byte-compared against a golden file; the encoding is then
-- redecoded and checked for structural equality.
module AsyncAPISpec (spec) where

import Control.Monad (forM_)
import Data.Aeson (Value (..), decode, eitherDecode, encode)
import Data.Aeson.KeyMap qualified as KM
import Data.Aeson.Types (parseEither)
import Data.ByteString (ByteString)
import Data.ByteString.Lazy qualified as BL
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.Encoding qualified as TE
import Data.Yaml qualified (decodeEither')
import System.FilePath ((<.>), (</>))
import Test.Hspec
import Test.Hspec.Golden (Golden)
import TestSupport

spec :: Spec
spec = describe "spec examples" $ do
  base <- runIO loadBaseDoc
  examples <- runIO (annotatedExamples <$> loadSpecMarkdown)
  mapM_ (exampleCase base) (zip [1 :: Int ..] examples)
  identifierExamples

exampleCase :: Value -> (Int, ExampleBlock) -> Spec
exampleCase base (idx, ex) = it label action
  where
    action :: IO (Golden ByteString)
    action = do
      fragment <- parseFragment ex
      let expectedValue =
            case blockPointer ex of
              Just "" -> mergePatch base fragment
              _ -> fragment
      case pointerType (maybe "" id (blockPointer ex)) of
        Nothing -> pendWith ("pointerType row pending for " <> show (blockPointer ex))
        Just (Target tname tparser) ->
          case parseEither tparser expectedValue of
            Left e ->
              failWith ("decoding as " <> tname <> " failed: " <> e)
            Right v -> do
              let out = BL.toStrict (encode v)
              case decode (BL.fromStrict out) of
                Just v' | v' == v -> pure (byteGolden ("spec-examples" </> goldenName idx ex) out)
                _ -> failWith "decode (encode v) /= v"
    label =
      T.unpack (maybe "" id (blockName ex))
        <> " ["
        <> T.unpack (blockFormat ex)
        <> "] at "
        <> T.unpack (maybe "" id (blockPointer ex))

-- | The four unannotated Identifier Object examples (spec lines 234, 240,
-- 244, 250): literal @id@ URI values, checked as plain JSON.
identifierExamples :: Spec
identifierExamples = do
  md <- runIO loadSpecMarkdown
  let ids =
        [ b
        | b <- allFencedBlocks md,
          blockLine b `elem` [234, 240, 244, 250]
        ]
  describe "identifier examples" $ do
    it "finds the four Identifier Object blocks" $ length ids `shouldBe` 4
    forM_ ids $ \b ->
      it ("line " <> show (blockLine b) <> " parses as an id object") $ do
        v <- parseFragment b
        case v of
          Object o | Just (String _) <- KM.lookup "id" o -> pure ()
          _ -> expectationFailure ("not an id object: " <> show v)

-- | Decode the block body (yaml or json) into an aeson value.
parseFragment :: ExampleBlock -> IO Value
parseFragment ex = do
  let bs = TE.encodeUtf8 (blockBody ex)
  case blockFormat ex of
    "json" -> either (fail . ("json parse: " <>)) pure (eitherDecode (BL.fromStrict bs))
    "yaml" -> either (fail . show) pure (Data.Yaml.decodeEither' bs)
    f -> fail ("unsupported format " <> show f)

-- | Golden file path for an example: @test/golden/spec-examples/<idx>-<name>-<format>.json@.
goldenName :: Int -> ExampleBlock -> String
goldenName idx ex =
  show idx
    <> "-"
    <> slug (maybe "unnamed" id (blockName ex))
    <> "-"
    <> T.unpack (blockFormat ex)
      <.> "json"

slug :: Text -> String
slug = map slugChar . T.unpack . T.toLower
  where
    slugChar ' ' = '-'
    slugChar c
      | c `elem` ("/.:()[]|, '\t" :: String) = '-'
      | otherwise = c
