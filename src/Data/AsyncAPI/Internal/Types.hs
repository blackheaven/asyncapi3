-- | Shared newtype wrappers for repeated text fields of the AsyncAPI 3.1.0
-- model. Every wrapper derives 'IsString' (string literals work under
-- 'OverloadedStrings') and newtype-derives JSON instances, so encoding and
-- decoding are byte-identical to bare 'Text'.
module Data.AsyncAPI.Internal.Types
  ( Title (..),
    Name (..),
    Version (..),
    Id (..),
    Summary (..),
    Description (..),
    Url (..),
    ContentType (..),
    RuntimeExpression (..),
  )
where

import Data.Aeson (FromJSON, ToJSON)
import Data.String (IsString)
import Data.Text (Text)

-- | The title of an API, server, channel, message, operation, or schema.
newtype Title = Title {getTitle :: Text}
  deriving stock (Eq, Ord, Show)
  deriving newtype (IsString, ToJSON, FromJSON)

-- | A machine- or human-assigned name (contact, license, tag, message, ...).
newtype Name = Name {getName :: Text}
  deriving stock (Eq, Ord, Show)
  deriving newtype (IsString, ToJSON, FromJSON)

-- | A version string (API version, spec version, protocol version).
newtype Version = Version {getVersion :: Text}
  deriving stock (Eq, Ord, Show)
  deriving newtype (IsString, ToJSON, FromJSON)

-- | The application identifier of an AsyncAPI document.
newtype Id = Id {getId :: Text}
  deriving stock (Eq, Ord, Show)
  deriving newtype (IsString, ToJSON, FromJSON)

-- | A short summary of a server, channel, message, or operation.
newtype Summary = Summary {getSummary :: Text}
  deriving stock (Eq, Ord, Show)
  deriving newtype (IsString, ToJSON, FromJSON)

-- | A prose description (CommonMark allowed).
newtype Description = Description {getDescription :: Text}
  deriving stock (Eq, Ord, Show)
  deriving newtype (IsString, ToJSON, FromJSON)

-- | A URL (terms of service, contact, license, documentation, OAuth, ...).
newtype Url = Url {getUrl :: Text}
  deriving stock (Eq, Ord, Show)
  deriving newtype (IsString, ToJSON, FromJSON)

-- | A media type for message payloads.
newtype ContentType = ContentType {getContentType :: Text}
  deriving stock (Eq, Ord, Show)
  deriving newtype (IsString, ToJSON, FromJSON)

-- | An AsyncAPI runtime expression (e.g. @$message.header#\/cid@).
newtype RuntimeExpression = RuntimeExpression {getRuntimeExpression :: Text}
  deriving stock (Eq, Ord, Show)
  deriving newtype (IsString, ToJSON, FromJSON)
