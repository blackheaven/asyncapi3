-- | Red-case-per-rule tests for the structural validator, plus a
-- clean-document case. Documents are built with lens field optics.
module ValidationSpec (spec) where

import Control.Lens ((&), (.~))
import Data.Aeson (object, (.=))
import Data.AsyncAPI
import Data.AsyncAPI.Lens
import Data.HashMap.Strict.InsOrd qualified as InsOrd
import Test.Hspec

spec :: Spec
spec = describe "validateAsyncAPI" $ do
  it "accepts a clean document" $
    validateAsyncAPI cleanDoc `shouldBe` []

  it "rejects a bad asyncapi version string" $
    validateAsyncAPI (cleanDoc & asyncAPI .~ "2.6.0")
      `shouldContain` [ValidationError VersionRule "" "unsupported asyncapi version: 2.6.0"]

  it "rejects a dangling internal reference" $ do
    let doc =
          cleanDoc
            & components .~ Just (emptyComponents {_componentsMessages = Just (InsOrd.singleton "none" (Ref (Reference "#/components/messages/missing")))})
    validateAsyncAPI doc
      `shouldContain` [ValidationError RefResolutionRule "/components/messages/none" "unresolved internal reference: #/components/messages/missing"]

  it "rejects an unsupported schemaFormat" $ do
    let mfs =
          MultiFormatSchema
            { _multiFormatSchemaSchemaFormat = "application/vnd.apache.avro+json;version=1.9.0",
              _multiFormatSchemaSchema = object ["x" .= (1 :: Int)],
              _multiFormatSchemaExtensions = InsOrd.empty
            }
        doc =
          cleanDoc
            & components .~ Just (emptyComponents {_componentsMessages = Just (InsOrd.singleton "avro" (Inline (messageWithPayload mfs)))})
    validateAsyncAPI doc
      `shouldContain` [ValidationError SchemaFormatRule "" "unsupported schemaFormat: application/vnd.apache.avro+json;version=1.9.0"]

cleanDoc :: AsyncAPI
cleanDoc =
  emptyAsyncAPI "3.1.0" (Info "Test" "1.0.0" Nothing Nothing Nothing Nothing Nothing Nothing InsOrd.empty)

messageWithPayload :: MultiFormatSchema -> Message
messageWithPayload mfs =
  Message
    { _messageHeaders = Nothing,
      _messagePayload = Just (SchemaDefMultiFormat mfs),
      _messageCorrelationId = Nothing,
      _messageContentType = Nothing,
      _messageName = Nothing,
      _messageTitle = Nothing,
      _messageSummary = Nothing,
      _messageDescription = Nothing,
      _messageTags = Nothing,
      _messageExternalDocs = Nothing,
      _messageBindings = Nothing,
      _messageExamples = Nothing,
      _messageTraits = Nothing,
      _messageExtensions = InsOrd.empty
    }
