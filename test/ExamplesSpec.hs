-- | Golden + validation tests over the real-world example documents vendored
-- from the spec repository (reference/examples/).
module ExamplesSpec (spec) where

import Control.Monad (forM, forM_)
import Data.Aeson (Value, decode, eitherDecode, encode, toJSON)
import Data.AsyncAPI (ValidationError (..), ValidationRule (..), validateAsyncAPI)
import Data.ByteString qualified as BS
import Data.ByteString.Lazy qualified as BL
import System.FilePath ((<.>), (</>))
import Test.Hspec
import Test.Hspec.Golden (Golden)
import TestSupport

spec :: Spec
spec = describe "real-world examples" $ do
  files <- runIO exampleFiles
  cases <-
    runIO
      ( forM files $ \f -> do
          v <- parseYamlFile f
          pure (f, v)
      )
  forM_ cases exampleCase

exampleCase :: (FilePath, Value) -> Spec
exampleCase (file, value) = it file $ do
  case eitherDecode (encode (toJSON value)) of
    Left e -> failWith ("decode as AsyncAPI failed: " <> e)
    Right doc ->
      case decode (encode doc) of
        Just doc'
          | doc' == doc ->
              case filter mustLevel (validateAsyncAPI doc) of
                [] -> pure (goldenFor file (BL.toStrict (encode doc)))
                errs ->
                  failWith
                    ( "validation errors: "
                        <> show [(validationPointer e, validationMessage e) | e <- errs]
                    )
        _ -> failWith "decode (encode v) /= v"
  where
    -- RECOMMENDED (non-MUST) schema formats (e.g. Avro) are valid documents;
    -- the validator only enforces the spec's MUST table, so skip its
    -- schemaFormat complaints here.
    mustLevel e = validationRule e /= SchemaFormatRule

goldenFor :: FilePath -> BS.ByteString -> Golden BS.ByteString
goldenFor file = byteGolden ("examples" </> map slash file <.> "json")
  where
    slash '/' = '-'
    slash c = c
