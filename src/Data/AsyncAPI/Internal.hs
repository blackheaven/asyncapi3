-- | The AsyncAPI 3.1.0 object model. Each type mirrors one section of the
-- specification; field order in every 'ToJSON' instance follows the Fixed
-- Fields table of that section.
module Data.AsyncAPI.Internal
  ( -- * Root
    AsyncAPI (..),
    emptyAsyncAPI,

    -- * Info family
    Info (..),
    emptyInfo,
    Contact (..),
    emptyContact,
    License (..),
    emptyLicense,

    -- * Servers
    Servers,
    Server (..),
    emptyServer,
    ServerVariable (..),
    emptyServerVariable,

    -- * Channels
    Channels,
    Channel (..),
    emptyChannel,
    Parameters,
    Parameter (..),
    emptyParameter,

    -- * Messages
    Messages,
    Message (..),
    emptyMessage,
    MessageTrait (..),
    emptyMessageTrait,
    MessageExample (..),
    emptyMessageExample,
    CorrelationId (..),
    emptyCorrelationId,
    SchemaDefinition (..),

    -- * Operations
    Operations,
    Operation (..),
    emptyOperation,
    OperationAction (..),
    OperationTrait (..),
    emptyOperationTrait,
    OperationReply (..),
    emptyOperationReply,
    OperationReplyAddress (..),
    emptyOperationReplyAddress,

    -- * Shared metadata
    Tags,
    Tag (..),
    ExternalDocumentation (..),
    Reference (..),
    Referenced (..),

    -- * Security
    SecurityScheme (..),
    emptySecurityScheme,
    SecuritySchemeType (..),
    ApiKeyLocation (..),
    OAuthFlows (..),
    emptyOAuthFlows,
    OAuthFlow (..),
    emptyOAuthFlow,

    -- * Bindings
    ServerBindings (..),
    emptyServerBindings,
    ChannelBindings (..),
    emptyChannelBindings,
    OperationBindings (..),
    emptyOperationBindings,
    MessageBindings (..),
    emptyMessageBindings,

    -- * Schema formats
    MultiFormatSchema (..),
    emptyMultiFormatSchema,

    -- * Components
    Components (..),
    emptyComponents,

    -- * Encoding helpers (re-exported for instances in this module)
    module Data.AsyncAPI.Internal.Encoding,
    module Data.AsyncAPI.Internal.Types,
  )
where

import Data.Aeson (FromJSON (..), ToJSON (..), Value (..), withObject, withText, (.!=), (.:), (.:?))
import Data.Aeson.KeyMap qualified as KM
import Data.AsyncAPI.Internal.Encoding
import Data.AsyncAPI.Internal.Referenced
import Data.AsyncAPI.Internal.Schema
import Data.AsyncAPI.Internal.Types
import Data.HashMap.Strict.InsOrd (InsOrdHashMap)
import Data.HashMap.Strict.InsOrd qualified as InsOrd
import Data.Text (Text)
import GHC.Generics (Generic)

-- $ root
--
-- [AsyncAPI 3.1.0 — AsyncAPI Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#A2SObject)

-- | The root document object of an AsyncAPI 3.1.0 document.
--
-- [AsyncAPI 3.1.0 — AsyncAPI Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#A2SObject)
data AsyncAPI = AsyncAPI
  { -- | **REQUIRED.** Specification version.
    -- [AsyncAPI Version String](https://www.asyncapi.com/docs/reference/specification/v3.1.0#A2SVersionString)
    _asyncAPIAsyncAPI :: Version,
    -- | Application identifier.
    -- [Identifier](https://www.asyncapi.com/docs/reference/specification/v3.1.0#A2SIdString)
    _asyncAPIId :: Maybe Id,
    -- | **REQUIRED.** Metadata about the API.
    -- [Info Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#infoObject)
    _asyncAPIInfo :: Info,
    -- | Connection details of servers.
    -- [Servers Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#serversObject)
    _asyncAPIServers :: Maybe Servers,
    -- | Default content type for message payloads.
    -- [Default Content Type](https://www.asyncapi.com/docs/reference/specification/v3.1.0#defaultContentTypeString)
    _asyncAPIDefaultContentType :: Maybe ContentType,
    -- | The channels used by this application.
    -- [Channels Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#channelsObject)
    _asyncAPIChannels :: Maybe Channels,
    -- | The operations this application MUST implement.
    -- [Operations Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#operationsObject)
    _asyncAPIOperations :: Maybe Operations,
    -- | Reusable objects.
    -- [Components Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#componentsObject)
    _asyncAPIComponents :: Maybe Components,
    -- | Specification extensions (@x-@).
    -- [Specification Extensions](https://www.asyncapi.com/docs/reference/specification/v3.1.0#specificationExtensions)
    _asyncAPIExtensions :: InsOrdHashMap Text Value
  }
  deriving (Eq, Show, Generic)

-- | A document with only the required fields set.
emptyAsyncAPI :: Version -> Info -> AsyncAPI
emptyAsyncAPI v i =
  AsyncAPI
    { _asyncAPIAsyncAPI = v,
      _asyncAPIId = Nothing,
      _asyncAPIInfo = i,
      _asyncAPIServers = Nothing,
      _asyncAPIDefaultContentType = Nothing,
      _asyncAPIChannels = Nothing,
      _asyncAPIOperations = Nothing,
      _asyncAPIComponents = Nothing,
      _asyncAPIExtensions = InsOrd.empty
    }

instance ToJSON AsyncAPI where
  toJSON = jsonViaEncoding
  toEncoding AsyncAPI {..} =
    recordEncoding
      _asyncAPIExtensions
      [ "asyncapi" .=? Just _asyncAPIAsyncAPI,
        "id" .=? _asyncAPIId,
        "info" .=? Just _asyncAPIInfo,
        "servers" .=? fmap SortedObject _asyncAPIServers,
        "defaultContentType" .=? _asyncAPIDefaultContentType,
        "channels" .=? fmap SortedObject _asyncAPIChannels,
        "operations" .=? fmap SortedObject _asyncAPIOperations,
        "components" .=? _asyncAPIComponents
      ]

instance FromJSON AsyncAPI where
  parseJSON = withObject "AsyncAPI" $ \o -> do
    _asyncAPIAsyncAPI <- o .: "asyncapi"
    _asyncAPIId <- o .:? "id"
    _asyncAPIInfo <- o .: "info"
    _asyncAPIServers <- sortedMapField "servers" o
    _asyncAPIDefaultContentType <- o .:? "defaultContentType"
    _asyncAPIChannels <- sortedMapField "channels" o
    _asyncAPIOperations <- sortedMapField "operations" o
    _asyncAPIComponents <- o .:? "components"
    let _asyncAPIExtensions = parseExtensions o
    pure AsyncAPI {..}

-- $ info
--
-- [AsyncAPI 3.1.0 — Info Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#infoObject)

-- | Metadata about the API.
--
-- [AsyncAPI 3.1.0 — Info Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#infoObject)
data Info = Info
  { -- | **REQUIRED.** The title of the application.
    _infoTitle :: Title,
    -- | **REQUIRED.** The version of the application API.
    _infoVersion :: Version,
    -- | A short description of the application.
    _infoDescription :: Maybe Description,
    -- | A URL to the Terms of Service.
    _infoTermsOfService :: Maybe Url,
    -- | Contact information.
    -- [Contact Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#contactObject)
    _infoContact :: Maybe Contact,
    -- | License information.
    -- [License Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#licenseObject)
    _infoLicense :: Maybe License,
    -- | A list of tags.
    -- [Tags Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#tagsObject)
    _infoTags :: Maybe Tags,
    -- | Additional external documentation.
    -- [External Documentation Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#externalDocumentationObject)
    _infoExternalDocs :: Maybe (Referenced ExternalDocumentation),
    -- | Specification extensions (@x-@).
    _infoExtensions :: InsOrdHashMap Text Value
  }
  deriving (Eq, Show, Generic)

instance ToJSON Info where
  toJSON = jsonViaEncoding
  toEncoding Info {..} =
    recordEncoding
      _infoExtensions
      [ "title" .=? Just _infoTitle,
        "version" .=? Just _infoVersion,
        "description" .=? _infoDescription,
        "termsOfService" .=? _infoTermsOfService,
        "contact" .=? _infoContact,
        "license" .=? _infoLicense,
        "tags" .=? _infoTags,
        "externalDocs" .=? _infoExternalDocs
      ]

instance FromJSON Info where
  parseJSON = withObject "Info" $ \o -> do
    _infoTitle <- o .: "title"
    _infoVersion <- o .: "version"
    _infoDescription <- o .:? "description"
    _infoTermsOfService <- o .:? "termsOfService"
    _infoContact <- o .:? "contact"
    _infoLicense <- o .:? "license"
    _infoTags <- o .:? "tags"
    _infoExternalDocs <- o .:? "externalDocs"
    let _infoExtensions = parseExtensions o
    pure Info {..}

-- | An 'Info' with only the required fields set.
emptyInfo :: Title -> Version -> Info
emptyInfo t v =
  Info
    { _infoTitle = t,
      _infoVersion = v,
      _infoDescription = Nothing,
      _infoTermsOfService = Nothing,
      _infoContact = Nothing,
      _infoLicense = Nothing,
      _infoTags = Nothing,
      _infoExternalDocs = Nothing,
      _infoExtensions = InsOrd.empty
    }

-- | Contact information for the exposed API.
--
-- [AsyncAPI 3.1.0 — Contact Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#contactObject)
data Contact = Contact
  { -- | The identifying name of the contact person\/organization.
    _contactName :: Maybe Name,
    -- | The URL pointing to the contact information.
    _contactUrl :: Maybe Url,
    -- | The email address of the contact person\/organization.
    _contactEmail :: Maybe Text,
    -- | Specification extensions (@x-@).
    _contactExtensions :: InsOrdHashMap Text Value
  }
  deriving (Eq, Show, Generic)

instance ToJSON Contact where
  toJSON = jsonViaEncoding
  toEncoding Contact {..} =
    recordEncoding
      _contactExtensions
      [ "name" .=? _contactName,
        "url" .=? _contactUrl,
        "email" .=? _contactEmail
      ]

instance FromJSON Contact where
  parseJSON = withObject "Contact" $ \o -> do
    _contactName <- o .:? "name"
    _contactUrl <- o .:? "url"
    _contactEmail <- o .:? "email"
    let _contactExtensions = parseExtensions o
    pure Contact {..}

-- | A 'Contact' with only the required fields set.
emptyContact :: Contact
emptyContact =
  Contact
    { _contactName = Nothing,
      _contactUrl = Nothing,
      _contactEmail = Nothing,
      _contactExtensions = InsOrd.empty
    }

-- | License information for the exposed API.
--
-- [AsyncAPI 3.1.0 — License Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#licenseObject)
data License = License
  { -- | **REQUIRED.** The license name used for the API.
    _licenseName :: Name,
    -- | A URL to the license used for the API.
    _licenseUrl :: Maybe Url,
    -- | Specification extensions (@x-@).
    _licenseExtensions :: InsOrdHashMap Text Value
  }
  deriving (Eq, Show, Generic)

instance ToJSON License where
  toJSON = jsonViaEncoding
  toEncoding License {..} =
    recordEncoding
      _licenseExtensions
      [ "name" .=? Just _licenseName,
        "url" .=? _licenseUrl
      ]

instance FromJSON License where
  parseJSON = withObject "License" $ \o -> do
    _licenseName <- o .: "name"
    _licenseUrl <- o .:? "url"
    let _licenseExtensions = parseExtensions o
    pure License {..}

-- | A 'License' with only the required fields set.
emptyLicense :: Name -> License
emptyLicense n =
  License
    { _licenseName = n,
      _licenseUrl = Nothing,
      _licenseExtensions = InsOrd.empty
    }

-- $ servers
--
-- [AsyncAPI 3.1.0 — Servers Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#serversObject)

-- | A map of server names to (possibly referenced) servers.
--
-- [AsyncAPI 3.1.0 — Servers Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#serversObject)
type Servers = InsOrdHashMap Text (Referenced Server)

-- | A message broker, server, or other program capable of sending and\/or
-- receiving data.
--
-- [AsyncAPI 3.1.0 — Server Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#serverObject)
data Server = Server
  { -- | **REQUIRED.** The server host name; MAY include the port.
    _serverHost :: Text,
    -- | **REQUIRED.** The protocol this server supports for connection.
    _serverProtocol :: Text,
    -- | The version of the protocol used for connection.
    _serverProtocolVersion :: Maybe Version,
    -- | The path to a resource in the host.
    _serverPathname :: Maybe Text,
    -- | An optional string describing the server.
    _serverDescription :: Maybe Description,
    -- | A human-friendly title for the server.
    _serverTitle :: Maybe Title,
    -- | A short summary of the server.
    _serverSummary :: Maybe Summary,
    -- | A map between a variable name and its value.
    -- [Server Variable Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#serverVariableObject)
    _serverVariables :: Maybe (InsOrdHashMap Text (Referenced ServerVariable)),
    -- | A declaration of which security schemes can be used with this server.
    -- [Security Scheme Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#securitySchemeObject)
    _serverSecurity :: Maybe [Referenced SecurityScheme],
    -- | A list of tags for logical grouping of servers.
    -- [Tags Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#tagsObject)
    _serverTags :: Maybe Tags,
    -- | Additional external documentation for this server.
    _serverExternalDocs :: Maybe (Referenced ExternalDocumentation),
    -- | Protocol-specific definitions for the server.
    -- [Server Bindings Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#serverBindingsObject)
    _serverBindings :: Maybe (Referenced ServerBindings),
    -- | Specification extensions (@x-@).
    _serverExtensions :: InsOrdHashMap Text Value
  }
  deriving (Eq, Show, Generic)

instance ToJSON Server where
  toJSON = jsonViaEncoding
  toEncoding Server {..} =
    recordEncoding
      _serverExtensions
      [ "host" .=? Just _serverHost,
        "protocol" .=? Just _serverProtocol,
        "protocolVersion" .=? _serverProtocolVersion,
        "pathname" .=? _serverPathname,
        "description" .=? _serverDescription,
        "title" .=? _serverTitle,
        "summary" .=? _serverSummary,
        "variables" .=? fmap SortedObject _serverVariables,
        "security" .=? _serverSecurity,
        "tags" .=? _serverTags,
        "externalDocs" .=? _serverExternalDocs,
        "bindings" .=? _serverBindings
      ]

instance FromJSON Server where
  parseJSON = withObject "Server" $ \o -> do
    _serverHost <- o .: "host"
    _serverProtocol <- o .: "protocol"
    _serverProtocolVersion <- o .:? "protocolVersion"
    _serverPathname <- o .:? "pathname"
    _serverDescription <- o .:? "description"
    _serverTitle <- o .:? "title"
    _serverSummary <- o .:? "summary"
    _serverVariables <- sortedMapField "variables" o
    _serverSecurity <- o .:? "security"
    _serverTags <- o .:? "tags"
    _serverExternalDocs <- o .:? "externalDocs"
    _serverBindings <- o .:? "bindings"
    let _serverExtensions = parseExtensions o
    pure Server {..}

-- | A 'Server' with only the required fields set.
emptyServer :: Text -> Text -> Server
emptyServer h p =
  Server
    { _serverHost = h,
      _serverProtocol = p,
      _serverProtocolVersion = Nothing,
      _serverPathname = Nothing,
      _serverDescription = Nothing,
      _serverTitle = Nothing,
      _serverSummary = Nothing,
      _serverVariables = Nothing,
      _serverSecurity = Nothing,
      _serverTags = Nothing,
      _serverExternalDocs = Nothing,
      _serverBindings = Nothing,
      _serverExtensions = InsOrd.empty
    }

-- | A server variable for URL template substitution.
--
-- [AsyncAPI 3.1.0 — Server Variable Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#serverVariableObject)
data ServerVariable = ServerVariable
  { -- | An enumeration of string values for substitution.
    _serverVariableEnum :: Maybe [Text],
    -- | The default value to use for substitution.
    _serverVariableDefault :: Maybe Text,
    -- | An optional description for the server variable.
    _serverVariableDescription :: Maybe Description,
    -- | An array of examples of the server variable.
    _serverVariableExamples :: Maybe [Text],
    -- | Specification extensions (@x-@).
    _serverVariableExtensions :: InsOrdHashMap Text Value
  }
  deriving (Eq, Show, Generic)

instance ToJSON ServerVariable where
  toJSON = jsonViaEncoding
  toEncoding ServerVariable {..} =
    recordEncoding
      _serverVariableExtensions
      [ "enum" .=? _serverVariableEnum,
        "default" .=? _serverVariableDefault,
        "description" .=? _serverVariableDescription,
        "examples" .=? _serverVariableExamples
      ]

instance FromJSON ServerVariable where
  parseJSON = withObject "ServerVariable" $ \o -> do
    _serverVariableEnum <- o .:? "enum"
    _serverVariableDefault <- o .:? "default"
    _serverVariableDescription <- o .:? "description"
    _serverVariableExamples <- o .:? "examples"
    let _serverVariableExtensions = parseExtensions o
    pure ServerVariable {..}

-- | A 'ServerVariable' with only the required fields set.
emptyServerVariable :: ServerVariable
emptyServerVariable =
  ServerVariable
    { _serverVariableEnum = Nothing,
      _serverVariableDefault = Nothing,
      _serverVariableDescription = Nothing,
      _serverVariableExamples = Nothing,
      _serverVariableExtensions = InsOrd.empty
    }

-- $ channels
--
-- [AsyncAPI 3.1.0 — Channels Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#channelsObject)

-- | A map of channel identifiers to (possibly referenced) channels.
--
-- [AsyncAPI 3.1.0 — Channels Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#channelsObject)
type Channels = InsOrdHashMap Text (Referenced Channel)

-- | A shared communication channel.
--
-- [AsyncAPI 3.1.0 — Channel Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#channelObject)
data Channel = Channel
  { -- | This channel's address (@null@ or absent = unknown).
    _channelAddress :: Maybe (Maybe Text),
    -- | Messages that will be sent to this channel.
    -- [Messages Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#messagesObject)
    _channelMessages :: Maybe Messages,
    -- | A human-friendly title for the channel.
    _channelTitle :: Maybe Title,
    -- | A short summary of the channel.
    _channelSummary :: Maybe Summary,
    -- | An optional description of this channel.
    _channelDescription :: Maybe Description,
    -- | @$ref@ pointers to the servers in which this channel is available.
    _channelServers :: Maybe [Reference],
    -- | Parameters included in the channel address.
    -- [Parameters Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#parametersObject)
    _channelParameters :: Maybe Parameters,
    -- | A list of tags for logical grouping of channels.
    _channelTags :: Maybe Tags,
    -- | Additional external documentation for this channel.
    _channelExternalDocs :: Maybe (Referenced ExternalDocumentation),
    -- | Protocol-specific definitions for the channel.
    -- [Channel Bindings Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#channelBindingsObject)
    _channelBindings :: Maybe (Referenced ChannelBindings),
    -- | Specification extensions (@x-@).
    _channelExtensions :: InsOrdHashMap Text Value
  }
  deriving (Eq, Show, Generic)

instance ToJSON Channel where
  toJSON = jsonViaEncoding
  toEncoding Channel {..} =
    recordEncoding
      _channelExtensions
      [ "address" .=? _channelAddress,
        "messages" .=? fmap SortedObject _channelMessages,
        "title" .=? _channelTitle,
        "summary" .=? _channelSummary,
        "description" .=? _channelDescription,
        "servers" .=? _channelServers,
        "parameters" .=? fmap SortedObject _channelParameters,
        "tags" .=? _channelTags,
        "externalDocs" .=? _channelExternalDocs,
        "bindings" .=? _channelBindings
      ]

instance FromJSON Channel where
  parseJSON = withObject "Channel" $ \o -> do
    _channelAddress <- o .:? "address"
    _channelMessages <- sortedMapField "messages" o
    _channelTitle <- o .:? "title"
    _channelSummary <- o .:? "summary"
    _channelDescription <- o .:? "description"
    _channelServers <- o .:? "servers"
    _channelParameters <- sortedMapField "parameters" o
    _channelTags <- o .:? "tags"
    _channelExternalDocs <- o .:? "externalDocs"
    _channelBindings <- o .:? "bindings"
    let _channelExtensions = parseExtensions o
    pure Channel {..}

-- | A 'Channel' with only the required fields set.
emptyChannel :: Channel
emptyChannel =
  Channel
    { _channelAddress = Nothing,
      _channelMessages = Nothing,
      _channelTitle = Nothing,
      _channelSummary = Nothing,
      _channelDescription = Nothing,
      _channelServers = Nothing,
      _channelParameters = Nothing,
      _channelTags = Nothing,
      _channelExternalDocs = Nothing,
      _channelBindings = Nothing,
      _channelExtensions = InsOrd.empty
    }

-- | A map of parameter names to (possibly referenced) parameters.
--
-- [AsyncAPI 3.1.0 — Parameters Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#parametersObject)
type Parameters = InsOrdHashMap Text (Referenced Parameter)

-- | A parameter included in a channel address.
--
-- [AsyncAPI 3.1.0 — Parameter Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#parameterObject)
data Parameter = Parameter
  { -- | An enumeration of string values for substitution.
    _parameterEnum :: Maybe [Text],
    -- | The default value to use for substitution.
    _parameterDefault :: Maybe Text,
    -- | An optional description for the parameter.
    _parameterDescription :: Maybe Description,
    -- | An array of examples of the parameter value.
    _parameterExamples :: Maybe [Text],
    -- | A runtime expression specifying the location of the parameter value.
    -- [Runtime Expression](https://www.asyncapi.com/docs/reference/specification/v3.1.0#runtimeExpression)
    _parameterLocation :: Maybe RuntimeExpression,
    -- | Specification extensions (@x-@).
    _parameterExtensions :: InsOrdHashMap Text Value
  }
  deriving (Eq, Show, Generic)

instance ToJSON Parameter where
  toJSON = jsonViaEncoding
  toEncoding Parameter {..} =
    recordEncoding
      _parameterExtensions
      [ "enum" .=? _parameterEnum,
        "default" .=? _parameterDefault,
        "description" .=? _parameterDescription,
        "examples" .=? _parameterExamples,
        "location" .=? _parameterLocation
      ]

instance FromJSON Parameter where
  parseJSON = withObject "Parameter" $ \o -> do
    _parameterEnum <- o .:? "enum"
    _parameterDefault <- o .:? "default"
    _parameterDescription <- o .:? "description"
    _parameterExamples <- o .:? "examples"
    _parameterLocation <- o .:? "location"
    let _parameterExtensions = parseExtensions o
    pure Parameter {..}

-- | A 'Parameter' with only the required fields set.
emptyParameter :: Parameter
emptyParameter =
  Parameter
    { _parameterEnum = Nothing,
      _parameterDefault = Nothing,
      _parameterDescription = Nothing,
      _parameterExamples = Nothing,
      _parameterLocation = Nothing,
      _parameterExtensions = InsOrd.empty
    }

-- $ security
--
-- [AsyncAPI 3.1.0 — Security Scheme Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#securitySchemeObject)

-- | The type of a security scheme; the valid values are exactly the ones
-- listed in the Security Scheme Object section.
--
-- [Security Scheme Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#securitySchemeObjectType)
data SecuritySchemeType
  = UserPassword
  | ApiKey
  | X509
  | SymmetricEncryption
  | AsymmetricEncryption
  | HttpApiKey
  | Http
  | OAuth2
  | OpenIdConnect
  | Plain
  | ScramSha256
  | ScramSha512
  | Gssapi
  deriving (Eq, Show, Generic)

instance ToJSON SecuritySchemeType where
  toJSON = jsonViaEncoding
  toEncoding t = toEncoding (securitySchemeTypeText t)

instance FromJSON SecuritySchemeType where
  parseJSON = withText "SecuritySchemeType" $ \t ->
    case securitySchemeTypeFromText t of
      Just st -> pure st
      Nothing -> fail ("unknown security scheme type: " <> show t)

securitySchemeTypeText :: SecuritySchemeType -> Text
securitySchemeTypeText = \case
  UserPassword -> "userPassword"
  ApiKey -> "apiKey"
  X509 -> "X509"
  SymmetricEncryption -> "symmetricEncryption"
  AsymmetricEncryption -> "asymmetricEncryption"
  HttpApiKey -> "httpApiKey"
  Http -> "http"
  OAuth2 -> "oauth2"
  OpenIdConnect -> "openIdConnect"
  Plain -> "plain"
  ScramSha256 -> "scramSha256"
  ScramSha512 -> "scramSha512"
  Gssapi -> "gssapi"

securitySchemeTypeFromText :: Text -> Maybe SecuritySchemeType
securitySchemeTypeFromText = \case
  "userPassword" -> Just UserPassword
  "apiKey" -> Just ApiKey
  "X509" -> Just X509
  "symmetricEncryption" -> Just SymmetricEncryption
  "asymmetricEncryption" -> Just AsymmetricEncryption
  "httpApiKey" -> Just HttpApiKey
  "http" -> Just Http
  "oauth2" -> Just OAuth2
  "openIdConnect" -> Just OpenIdConnect
  "plain" -> Just Plain
  "scramSha256" -> Just ScramSha256
  "scramSha512" -> Just ScramSha512
  "gssapi" -> Just Gssapi
  _ -> Nothing

-- | The location of an API key.
--
-- [Security Scheme Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#securitySchemeObjectIn)
data ApiKeyLocation
  = -- | @user@ (only for @apiKey@).
    InUser
  | -- | @password@ (only for @apiKey@).
    InPassword
  | -- | @query@ (only for @httpApiKey@).
    InQuery
  | -- | @header@ (only for @httpApiKey@).
    InHeader
  | -- | @cookie@ (only for @httpApiKey@).
    InCookie
  deriving (Eq, Show, Generic)

instance ToJSON ApiKeyLocation where
  toJSON = jsonViaEncoding
  toEncoding l = toEncoding $ case l of
    InUser -> "user" :: Text
    InPassword -> "password"
    InQuery -> "query"
    InHeader -> "header"
    InCookie -> "cookie"

instance FromJSON ApiKeyLocation where
  parseJSON = withText "ApiKeyLocation" $ \case
    "user" -> pure InUser
    "password" -> pure InPassword
    "query" -> pure InQuery
    "header" -> pure InHeader
    "cookie" -> pure InCookie
    t -> fail ("unknown API key location: " <> show t)

-- | Defines a security scheme that can be used by the operations.
--
-- [AsyncAPI 3.1.0 — Security Scheme Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#securitySchemeObject)
data SecurityScheme = SecurityScheme
  { -- | **REQUIRED.** The type of the security scheme.
    -- [Security Scheme Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#securitySchemeObjectType)
    _securitySchemeType :: SecuritySchemeType,
    -- | A short description for the security scheme.
    _securitySchemeDescription :: Maybe Description,
    -- | **REQUIRED** for @httpApiKey@: the name of the header, query or
    -- cookie parameter to be used.
    _securitySchemeName :: Maybe Name,
    -- | **REQUIRED** for @apiKey@ and @httpApiKey@: the location of the API key.
    _securitySchemeIn :: Maybe ApiKeyLocation,
    -- | **REQUIRED** for @http@: the HTTP Authorization scheme name.
    _securitySchemeScheme :: Maybe Text,
    -- | A hint to the client on the bearer token format.
    _securitySchemeBearerFormat :: Maybe Text,
    -- | **REQUIRED** for @oauth2@: configuration of the supported flows.
    -- [OAuth Flows Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#oauthFlowsObject)
    _securitySchemeFlows :: Maybe OAuthFlows,
    -- | **REQUIRED** for @openIdConnect@: the OpenId Connect URL.
    _securitySchemeOpenIdConnectUrl :: Maybe Url,
    -- | The needed scope names; an empty list means no scopes are needed.
    _securitySchemeScopes :: Maybe [Text],
    -- | Specification extensions (@x-@).
    _securitySchemeExtensions :: InsOrdHashMap Text Value
  }
  deriving (Eq, Show, Generic)

instance ToJSON SecurityScheme where
  toJSON = jsonViaEncoding
  toEncoding SecurityScheme {..} =
    recordEncoding
      _securitySchemeExtensions
      [ "type" .=? Just _securitySchemeType,
        "description" .=? _securitySchemeDescription,
        "name" .=? _securitySchemeName,
        "in" .=? _securitySchemeIn,
        "scheme" .=? _securitySchemeScheme,
        "bearerFormat" .=? _securitySchemeBearerFormat,
        "flows" .=? _securitySchemeFlows,
        "openIdConnectUrl" .=? _securitySchemeOpenIdConnectUrl,
        "scopes" .=? _securitySchemeScopes
      ]

instance FromJSON SecurityScheme where
  parseJSON = withObject "SecurityScheme" $ \o -> do
    _securitySchemeType <- o .: "type"
    _securitySchemeDescription <- o .:? "description"
    _securitySchemeName <- o .:? "name"
    _securitySchemeIn <- o .:? "in"
    _securitySchemeScheme <- o .:? "scheme"
    _securitySchemeBearerFormat <- o .:? "bearerFormat"
    _securitySchemeFlows <- o .:? "flows"
    _securitySchemeOpenIdConnectUrl <- o .:? "openIdConnectUrl"
    _securitySchemeScopes <- o .:? "scopes"
    let _securitySchemeExtensions = parseExtensions o
    pure SecurityScheme {..}

-- | A 'SecurityScheme' with only the required fields set.
emptySecurityScheme :: SecuritySchemeType -> SecurityScheme
emptySecurityScheme t =
  SecurityScheme
    { _securitySchemeType = t,
      _securitySchemeDescription = Nothing,
      _securitySchemeName = Nothing,
      _securitySchemeIn = Nothing,
      _securitySchemeScheme = Nothing,
      _securitySchemeBearerFormat = Nothing,
      _securitySchemeFlows = Nothing,
      _securitySchemeOpenIdConnectUrl = Nothing,
      _securitySchemeScopes = Nothing,
      _securitySchemeExtensions = InsOrd.empty
    }

-- | Configuration of the supported OAuth flows.
--
-- [AsyncAPI 3.1.0 — OAuth Flows Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#oauthFlowsObject)
data OAuthFlows = OAuthFlows
  { -- | Configuration for the OAuth Implicit flow.
    _oAuthFlowsImplicit :: Maybe OAuthFlow,
    -- | Configuration for the OAuth Resource Owner Protected Credentials flow.
    _oAuthFlowsPassword :: Maybe OAuthFlow,
    -- | Configuration for the OAuth Client Credentials flow.
    _oAuthFlowsClientCredentials :: Maybe OAuthFlow,
    -- | Configuration for the OAuth Authorization Code flow.
    _oAuthFlowsAuthorizationCode :: Maybe OAuthFlow,
    -- | Specification extensions (@x-@).
    _oAuthFlowsExtensions :: InsOrdHashMap Text Value
  }
  deriving (Eq, Show, Generic)

instance ToJSON OAuthFlows where
  toJSON = jsonViaEncoding
  toEncoding OAuthFlows {..} =
    recordEncoding
      _oAuthFlowsExtensions
      [ "implicit" .=? _oAuthFlowsImplicit,
        "password" .=? _oAuthFlowsPassword,
        "clientCredentials" .=? _oAuthFlowsClientCredentials,
        "authorizationCode" .=? _oAuthFlowsAuthorizationCode
      ]

instance FromJSON OAuthFlows where
  parseJSON = withObject "OAuthFlows" $ \o -> do
    _oAuthFlowsImplicit <- o .:? "implicit"
    _oAuthFlowsPassword <- o .:? "password"
    _oAuthFlowsClientCredentials <- o .:? "clientCredentials"
    _oAuthFlowsAuthorizationCode <- o .:? "authorizationCode"
    let _oAuthFlowsExtensions = parseExtensions o
    pure OAuthFlows {..}

-- | An 'OAuthFlows' with only the required fields set.
emptyOAuthFlows :: OAuthFlows
emptyOAuthFlows =
  OAuthFlows
    { _oAuthFlowsImplicit = Nothing,
      _oAuthFlowsPassword = Nothing,
      _oAuthFlowsClientCredentials = Nothing,
      _oAuthFlowsAuthorizationCode = Nothing,
      _oAuthFlowsExtensions = InsOrd.empty
    }

-- | Configuration details for a supported OAuth flow.
--
-- [AsyncAPI 3.1.0 — OAuth Flow Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#oauthFlowObject)
data OAuthFlow = OAuthFlow
  { -- | **REQUIRED** for @implicit@ and @authorizationCode@: the
    -- authorization URL.
    _oAuthFlowAuthorizationUrl :: Maybe Url,
    -- | **REQUIRED** for @password@, @clientCredentials@ and
    -- @authorizationCode@: the token URL.
    _oAuthFlowTokenUrl :: Maybe Url,
    -- | The URL for obtaining refresh tokens.
    _oAuthFlowRefreshUrl :: Maybe Url,
    -- | **REQUIRED.** The available scopes with a short description each
    -- (JSON key @availableScopes@).
    _oAuthFlowAvailableScopes :: InsOrdHashMap Text Text,
    -- | Specification extensions (@x-@).
    _oAuthFlowExtensions :: InsOrdHashMap Text Value
  }
  deriving (Eq, Show, Generic)

instance ToJSON OAuthFlow where
  toJSON = jsonViaEncoding
  toEncoding OAuthFlow {..} =
    recordEncoding
      _oAuthFlowExtensions
      [ "authorizationUrl" .=? _oAuthFlowAuthorizationUrl,
        "tokenUrl" .=? _oAuthFlowTokenUrl,
        "refreshUrl" .=? _oAuthFlowRefreshUrl,
        "availableScopes" .=? Just (SortedObject _oAuthFlowAvailableScopes)
      ]

instance FromJSON OAuthFlow where
  parseJSON = withObject "OAuthFlow" $ \o -> do
    _oAuthFlowAuthorizationUrl <- o .:? "authorizationUrl"
    _oAuthFlowTokenUrl <- o .:? "tokenUrl"
    _oAuthFlowRefreshUrl <- o .:? "refreshUrl"
    _oAuthFlowAvailableScopes <-
      sortInsOrd . unSortedObject <$> (o .: "availableScopes" .!= SortedObject InsOrd.empty)
    let _oAuthFlowExtensions = parseExtensions o
    pure OAuthFlow {..}

-- | An 'OAuthFlow' with only the required fields set.
emptyOAuthFlow :: InsOrdHashMap Text Text -> OAuthFlow
emptyOAuthFlow scopes =
  OAuthFlow
    { _oAuthFlowAuthorizationUrl = Nothing,
      _oAuthFlowTokenUrl = Nothing,
      _oAuthFlowRefreshUrl = Nothing,
      _oAuthFlowAvailableScopes = scopes,
      _oAuthFlowExtensions = InsOrd.empty
    }

-- $ bindings
--
-- Protocol binding internals are defined by the external
-- [asyncapi\/bindings](https://github.com/asyncapi/bindings) repository, so
-- each protocol's value is kept opaque as a JSON 'Value'.

-- | Protocol-specific definitions for a server.
--
-- [AsyncAPI 3.1.0 — Server Bindings Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#serverBindingsObject)
data ServerBindings = ServerBindings
  { _serverBindingsHttp :: Maybe Value,
    _serverBindingsWs :: Maybe Value,
    _serverBindingsKafka :: Maybe Value,
    _serverBindingsAnypointmq :: Maybe Value,
    _serverBindingsAmqp :: Maybe Value,
    _serverBindingsAmqp1 :: Maybe Value,
    _serverBindingsMqtt :: Maybe Value,
    _serverBindingsMqtt5 :: Maybe Value,
    _serverBindingsNats :: Maybe Value,
    _serverBindingsJms :: Maybe Value,
    _serverBindingsSns :: Maybe Value,
    _serverBindingsSolace :: Maybe Value,
    _serverBindingsSqs :: Maybe Value,
    _serverBindingsStomp :: Maybe Value,
    _serverBindingsRedis :: Maybe Value,
    _serverBindingsMercure :: Maybe Value,
    _serverBindingsIbmmq :: Maybe Value,
    _serverBindingsGooglepubsub :: Maybe Value,
    _serverBindingsPulsar :: Maybe Value,
    _serverBindingsRos2 :: Maybe Value,
    _serverBindingsExtensions :: InsOrdHashMap Text Value
  }
  deriving (Eq, Show, Generic)

instance ToJSON ServerBindings where
  toJSON = jsonViaEncoding
  toEncoding ServerBindings {..} =
    recordEncoding
      _serverBindingsExtensions
      [ "http" .=? _serverBindingsHttp,
        "ws" .=? _serverBindingsWs,
        "kafka" .=? _serverBindingsKafka,
        "anypointmq" .=? _serverBindingsAnypointmq,
        "amqp" .=? _serverBindingsAmqp,
        "amqp1" .=? _serverBindingsAmqp1,
        "mqtt" .=? _serverBindingsMqtt,
        "mqtt5" .=? _serverBindingsMqtt5,
        "nats" .=? _serverBindingsNats,
        "jms" .=? _serverBindingsJms,
        "sns" .=? _serverBindingsSns,
        "solace" .=? _serverBindingsSolace,
        "sqs" .=? _serverBindingsSqs,
        "stomp" .=? _serverBindingsStomp,
        "redis" .=? _serverBindingsRedis,
        "mercure" .=? _serverBindingsMercure,
        "ibmmq" .=? _serverBindingsIbmmq,
        "googlepubsub" .=? _serverBindingsGooglepubsub,
        "pulsar" .=? _serverBindingsPulsar,
        "ros2" .=? _serverBindingsRos2
      ]

instance FromJSON ServerBindings where
  parseJSON = withObject "ServerBindings" $ \o -> do
    _serverBindingsHttp <- o .:? "http"
    _serverBindingsWs <- o .:? "ws"
    _serverBindingsKafka <- o .:? "kafka"
    _serverBindingsAnypointmq <- o .:? "anypointmq"
    _serverBindingsAmqp <- o .:? "amqp"
    _serverBindingsAmqp1 <- o .:? "amqp1"
    _serverBindingsMqtt <- o .:? "mqtt"
    _serverBindingsMqtt5 <- o .:? "mqtt5"
    _serverBindingsNats <- o .:? "nats"
    _serverBindingsJms <- o .:? "jms"
    _serverBindingsSns <- o .:? "sns"
    _serverBindingsSolace <- o .:? "solace"
    _serverBindingsSqs <- o .:? "sqs"
    _serverBindingsStomp <- o .:? "stomp"
    _serverBindingsRedis <- o .:? "redis"
    _serverBindingsMercure <- o .:? "mercure"
    _serverBindingsIbmmq <- o .:? "ibmmq"
    _serverBindingsGooglepubsub <- o .:? "googlepubsub"
    _serverBindingsPulsar <- o .:? "pulsar"
    _serverBindingsRos2 <- o .:? "ros2"
    let _serverBindingsExtensions = parseExtensions o
    pure ServerBindings {..}

-- | A 'ServerBindings' with only the required fields set.
emptyServerBindings :: ServerBindings
emptyServerBindings =
  ServerBindings
    { _serverBindingsHttp = Nothing,
      _serverBindingsWs = Nothing,
      _serverBindingsKafka = Nothing,
      _serverBindingsAnypointmq = Nothing,
      _serverBindingsAmqp = Nothing,
      _serverBindingsAmqp1 = Nothing,
      _serverBindingsMqtt = Nothing,
      _serverBindingsMqtt5 = Nothing,
      _serverBindingsNats = Nothing,
      _serverBindingsJms = Nothing,
      _serverBindingsSns = Nothing,
      _serverBindingsSolace = Nothing,
      _serverBindingsSqs = Nothing,
      _serverBindingsStomp = Nothing,
      _serverBindingsRedis = Nothing,
      _serverBindingsMercure = Nothing,
      _serverBindingsIbmmq = Nothing,
      _serverBindingsGooglepubsub = Nothing,
      _serverBindingsPulsar = Nothing,
      _serverBindingsRos2 = Nothing,
      _serverBindingsExtensions = InsOrd.empty
    }

-- | Protocol-specific definitions for a channel.
--
-- [AsyncAPI 3.1.0 — Channel Bindings Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#channelBindingsObject)
data ChannelBindings = ChannelBindings
  { _channelBindingsHttp :: Maybe Value,
    _channelBindingsWs :: Maybe Value,
    _channelBindingsKafka :: Maybe Value,
    _channelBindingsAnypointmq :: Maybe Value,
    _channelBindingsAmqp :: Maybe Value,
    _channelBindingsAmqp1 :: Maybe Value,
    _channelBindingsMqtt :: Maybe Value,
    _channelBindingsMqtt5 :: Maybe Value,
    _channelBindingsNats :: Maybe Value,
    _channelBindingsJms :: Maybe Value,
    _channelBindingsSns :: Maybe Value,
    _channelBindingsSolace :: Maybe Value,
    _channelBindingsSqs :: Maybe Value,
    _channelBindingsStomp :: Maybe Value,
    _channelBindingsRedis :: Maybe Value,
    _channelBindingsMercure :: Maybe Value,
    _channelBindingsIbmmq :: Maybe Value,
    _channelBindingsGooglepubsub :: Maybe Value,
    _channelBindingsPulsar :: Maybe Value,
    _channelBindingsRos2 :: Maybe Value,
    _channelBindingsExtensions :: InsOrdHashMap Text Value
  }
  deriving (Eq, Show, Generic)

instance ToJSON ChannelBindings where
  toJSON = jsonViaEncoding
  toEncoding ChannelBindings {..} =
    recordEncoding
      _channelBindingsExtensions
      [ "http" .=? _channelBindingsHttp,
        "ws" .=? _channelBindingsWs,
        "kafka" .=? _channelBindingsKafka,
        "anypointmq" .=? _channelBindingsAnypointmq,
        "amqp" .=? _channelBindingsAmqp,
        "amqp1" .=? _channelBindingsAmqp1,
        "mqtt" .=? _channelBindingsMqtt,
        "mqtt5" .=? _channelBindingsMqtt5,
        "nats" .=? _channelBindingsNats,
        "jms" .=? _channelBindingsJms,
        "sns" .=? _channelBindingsSns,
        "solace" .=? _channelBindingsSolace,
        "sqs" .=? _channelBindingsSqs,
        "stomp" .=? _channelBindingsStomp,
        "redis" .=? _channelBindingsRedis,
        "mercure" .=? _channelBindingsMercure,
        "ibmmq" .=? _channelBindingsIbmmq,
        "googlepubsub" .=? _channelBindingsGooglepubsub,
        "pulsar" .=? _channelBindingsPulsar,
        "ros2" .=? _channelBindingsRos2
      ]

instance FromJSON ChannelBindings where
  parseJSON = withObject "ChannelBindings" $ \o -> do
    _channelBindingsHttp <- o .:? "http"
    _channelBindingsWs <- o .:? "ws"
    _channelBindingsKafka <- o .:? "kafka"
    _channelBindingsAnypointmq <- o .:? "anypointmq"
    _channelBindingsAmqp <- o .:? "amqp"
    _channelBindingsAmqp1 <- o .:? "amqp1"
    _channelBindingsMqtt <- o .:? "mqtt"
    _channelBindingsMqtt5 <- o .:? "mqtt5"
    _channelBindingsNats <- o .:? "nats"
    _channelBindingsJms <- o .:? "jms"
    _channelBindingsSns <- o .:? "sns"
    _channelBindingsSolace <- o .:? "solace"
    _channelBindingsSqs <- o .:? "sqs"
    _channelBindingsStomp <- o .:? "stomp"
    _channelBindingsRedis <- o .:? "redis"
    _channelBindingsMercure <- o .:? "mercure"
    _channelBindingsIbmmq <- o .:? "ibmmq"
    _channelBindingsGooglepubsub <- o .:? "googlepubsub"
    _channelBindingsPulsar <- o .:? "pulsar"
    _channelBindingsRos2 <- o .:? "ros2"
    let _channelBindingsExtensions = parseExtensions o
    pure ChannelBindings {..}

-- | A 'ChannelBindings' with only the required fields set.
emptyChannelBindings :: ChannelBindings
emptyChannelBindings =
  ChannelBindings
    { _channelBindingsHttp = Nothing,
      _channelBindingsWs = Nothing,
      _channelBindingsKafka = Nothing,
      _channelBindingsAnypointmq = Nothing,
      _channelBindingsAmqp = Nothing,
      _channelBindingsAmqp1 = Nothing,
      _channelBindingsMqtt = Nothing,
      _channelBindingsMqtt5 = Nothing,
      _channelBindingsNats = Nothing,
      _channelBindingsJms = Nothing,
      _channelBindingsSns = Nothing,
      _channelBindingsSolace = Nothing,
      _channelBindingsSqs = Nothing,
      _channelBindingsStomp = Nothing,
      _channelBindingsRedis = Nothing,
      _channelBindingsMercure = Nothing,
      _channelBindingsIbmmq = Nothing,
      _channelBindingsGooglepubsub = Nothing,
      _channelBindingsPulsar = Nothing,
      _channelBindingsRos2 = Nothing,
      _channelBindingsExtensions = InsOrd.empty
    }

-- | Protocol-specific definitions for an operation.
--
-- [AsyncAPI 3.1.0 — Operation Bindings Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#operationBindingsObject)
data OperationBindings = OperationBindings
  { _operationBindingsHttp :: Maybe Value,
    _operationBindingsWs :: Maybe Value,
    _operationBindingsKafka :: Maybe Value,
    _operationBindingsAnypointmq :: Maybe Value,
    _operationBindingsAmqp :: Maybe Value,
    _operationBindingsAmqp1 :: Maybe Value,
    _operationBindingsMqtt :: Maybe Value,
    _operationBindingsMqtt5 :: Maybe Value,
    _operationBindingsNats :: Maybe Value,
    _operationBindingsJms :: Maybe Value,
    _operationBindingsSns :: Maybe Value,
    _operationBindingsSolace :: Maybe Value,
    _operationBindingsSqs :: Maybe Value,
    _operationBindingsStomp :: Maybe Value,
    _operationBindingsRedis :: Maybe Value,
    _operationBindingsMercure :: Maybe Value,
    _operationBindingsGooglepubsub :: Maybe Value,
    _operationBindingsIbmmq :: Maybe Value,
    _operationBindingsPulsar :: Maybe Value,
    _operationBindingsRos2 :: Maybe Value,
    _operationBindingsExtensions :: InsOrdHashMap Text Value
  }
  deriving (Eq, Show, Generic)

instance ToJSON OperationBindings where
  toJSON = jsonViaEncoding
  toEncoding OperationBindings {..} =
    recordEncoding
      _operationBindingsExtensions
      [ "http" .=? _operationBindingsHttp,
        "ws" .=? _operationBindingsWs,
        "kafka" .=? _operationBindingsKafka,
        "anypointmq" .=? _operationBindingsAnypointmq,
        "amqp" .=? _operationBindingsAmqp,
        "amqp1" .=? _operationBindingsAmqp1,
        "mqtt" .=? _operationBindingsMqtt,
        "mqtt5" .=? _operationBindingsMqtt5,
        "nats" .=? _operationBindingsNats,
        "jms" .=? _operationBindingsJms,
        "sns" .=? _operationBindingsSns,
        "solace" .=? _operationBindingsSolace,
        "sqs" .=? _operationBindingsSqs,
        "stomp" .=? _operationBindingsStomp,
        "redis" .=? _operationBindingsRedis,
        "mercure" .=? _operationBindingsMercure,
        "googlepubsub" .=? _operationBindingsGooglepubsub,
        "ibmmq" .=? _operationBindingsIbmmq,
        "pulsar" .=? _operationBindingsPulsar,
        "ros2" .=? _operationBindingsRos2
      ]

instance FromJSON OperationBindings where
  parseJSON = withObject "OperationBindings" $ \o -> do
    _operationBindingsHttp <- o .:? "http"
    _operationBindingsWs <- o .:? "ws"
    _operationBindingsKafka <- o .:? "kafka"
    _operationBindingsAnypointmq <- o .:? "anypointmq"
    _operationBindingsAmqp <- o .:? "amqp"
    _operationBindingsAmqp1 <- o .:? "amqp1"
    _operationBindingsMqtt <- o .:? "mqtt"
    _operationBindingsMqtt5 <- o .:? "mqtt5"
    _operationBindingsNats <- o .:? "nats"
    _operationBindingsJms <- o .:? "jms"
    _operationBindingsSns <- o .:? "sns"
    _operationBindingsSolace <- o .:? "solace"
    _operationBindingsSqs <- o .:? "sqs"
    _operationBindingsStomp <- o .:? "stomp"
    _operationBindingsRedis <- o .:? "redis"
    _operationBindingsMercure <- o .:? "mercure"
    _operationBindingsGooglepubsub <- o .:? "googlepubsub"
    _operationBindingsIbmmq <- o .:? "ibmmq"
    _operationBindingsPulsar <- o .:? "pulsar"
    _operationBindingsRos2 <- o .:? "ros2"
    let _operationBindingsExtensions = parseExtensions o
    pure OperationBindings {..}

-- | An 'OperationBindings' with only the required fields set.
emptyOperationBindings :: OperationBindings
emptyOperationBindings =
  OperationBindings
    { _operationBindingsHttp = Nothing,
      _operationBindingsWs = Nothing,
      _operationBindingsKafka = Nothing,
      _operationBindingsAnypointmq = Nothing,
      _operationBindingsAmqp = Nothing,
      _operationBindingsAmqp1 = Nothing,
      _operationBindingsMqtt = Nothing,
      _operationBindingsMqtt5 = Nothing,
      _operationBindingsNats = Nothing,
      _operationBindingsJms = Nothing,
      _operationBindingsSns = Nothing,
      _operationBindingsSolace = Nothing,
      _operationBindingsSqs = Nothing,
      _operationBindingsStomp = Nothing,
      _operationBindingsRedis = Nothing,
      _operationBindingsMercure = Nothing,
      _operationBindingsGooglepubsub = Nothing,
      _operationBindingsIbmmq = Nothing,
      _operationBindingsPulsar = Nothing,
      _operationBindingsRos2 = Nothing,
      _operationBindingsExtensions = InsOrd.empty
    }

-- | Protocol-specific definitions for a message.
--
-- [AsyncAPI 3.1.0 — Message Bindings Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#messageBindingsObject)
data MessageBindings = MessageBindings
  { _messageBindingsHttp :: Maybe Value,
    _messageBindingsWs :: Maybe Value,
    _messageBindingsKafka :: Maybe Value,
    _messageBindingsAnypointmq :: Maybe Value,
    _messageBindingsAmqp :: Maybe Value,
    _messageBindingsAmqp1 :: Maybe Value,
    _messageBindingsMqtt :: Maybe Value,
    _messageBindingsMqtt5 :: Maybe Value,
    _messageBindingsNats :: Maybe Value,
    _messageBindingsJms :: Maybe Value,
    _messageBindingsSns :: Maybe Value,
    _messageBindingsSolace :: Maybe Value,
    _messageBindingsSqs :: Maybe Value,
    _messageBindingsStomp :: Maybe Value,
    _messageBindingsRedis :: Maybe Value,
    _messageBindingsMercure :: Maybe Value,
    _messageBindingsIbmmq :: Maybe Value,
    _messageBindingsGooglepubsub :: Maybe Value,
    _messageBindingsPulsar :: Maybe Value,
    _messageBindingsRos2 :: Maybe Value,
    _messageBindingsExtensions :: InsOrdHashMap Text Value
  }
  deriving (Eq, Show, Generic)

instance ToJSON MessageBindings where
  toJSON = jsonViaEncoding
  toEncoding MessageBindings {..} =
    recordEncoding
      _messageBindingsExtensions
      [ "http" .=? _messageBindingsHttp,
        "ws" .=? _messageBindingsWs,
        "kafka" .=? _messageBindingsKafka,
        "anypointmq" .=? _messageBindingsAnypointmq,
        "amqp" .=? _messageBindingsAmqp,
        "amqp1" .=? _messageBindingsAmqp1,
        "mqtt" .=? _messageBindingsMqtt,
        "mqtt5" .=? _messageBindingsMqtt5,
        "nats" .=? _messageBindingsNats,
        "jms" .=? _messageBindingsJms,
        "sns" .=? _messageBindingsSns,
        "solace" .=? _messageBindingsSolace,
        "sqs" .=? _messageBindingsSqs,
        "stomp" .=? _messageBindingsStomp,
        "redis" .=? _messageBindingsRedis,
        "mercure" .=? _messageBindingsMercure,
        "ibmmq" .=? _messageBindingsIbmmq,
        "googlepubsub" .=? _messageBindingsGooglepubsub,
        "pulsar" .=? _messageBindingsPulsar,
        "ros2" .=? _messageBindingsRos2
      ]

instance FromJSON MessageBindings where
  parseJSON = withObject "MessageBindings" $ \o -> do
    _messageBindingsHttp <- o .:? "http"
    _messageBindingsWs <- o .:? "ws"
    _messageBindingsKafka <- o .:? "kafka"
    _messageBindingsAnypointmq <- o .:? "anypointmq"
    _messageBindingsAmqp <- o .:? "amqp"
    _messageBindingsAmqp1 <- o .:? "amqp1"
    _messageBindingsMqtt <- o .:? "mqtt"
    _messageBindingsMqtt5 <- o .:? "mqtt5"
    _messageBindingsNats <- o .:? "nats"
    _messageBindingsJms <- o .:? "jms"
    _messageBindingsSns <- o .:? "sns"
    _messageBindingsSolace <- o .:? "solace"
    _messageBindingsSqs <- o .:? "sqs"
    _messageBindingsStomp <- o .:? "stomp"
    _messageBindingsRedis <- o .:? "redis"
    _messageBindingsMercure <- o .:? "mercure"
    _messageBindingsIbmmq <- o .:? "ibmmq"
    _messageBindingsGooglepubsub <- o .:? "googlepubsub"
    _messageBindingsPulsar <- o .:? "pulsar"
    _messageBindingsRos2 <- o .:? "ros2"
    let _messageBindingsExtensions = parseExtensions o
    pure MessageBindings {..}

-- | A 'MessageBindings' with only the required fields set.
emptyMessageBindings :: MessageBindings
emptyMessageBindings =
  MessageBindings
    { _messageBindingsHttp = Nothing,
      _messageBindingsWs = Nothing,
      _messageBindingsKafka = Nothing,
      _messageBindingsAnypointmq = Nothing,
      _messageBindingsAmqp = Nothing,
      _messageBindingsAmqp1 = Nothing,
      _messageBindingsMqtt = Nothing,
      _messageBindingsMqtt5 = Nothing,
      _messageBindingsNats = Nothing,
      _messageBindingsJms = Nothing,
      _messageBindingsSns = Nothing,
      _messageBindingsSolace = Nothing,
      _messageBindingsSqs = Nothing,
      _messageBindingsStomp = Nothing,
      _messageBindingsRedis = Nothing,
      _messageBindingsMercure = Nothing,
      _messageBindingsIbmmq = Nothing,
      _messageBindingsGooglepubsub = Nothing,
      _messageBindingsPulsar = Nothing,
      _messageBindingsRos2 = Nothing,
      _messageBindingsExtensions = InsOrd.empty
    }

-- $ mfs
--
-- [AsyncAPI 3.1.0 — Multi Format Schema Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#multiFormatSchemaObject)

-- | A schema definition supporting multiple schema formats or languages.
--
-- [AsyncAPI 3.1.0 — Multi Format Schema Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#multiFormatSchemaObject)
data MultiFormatSchema = MultiFormatSchema
  { -- | **REQUIRED.** Name of the schema format used to define the schema.
    -- [Schema formats table](https://www.asyncapi.com/docs/reference/specification/v3.1.0#multiFormatSchemaFormatTable)
    _multiFormatSchemaSchemaFormat :: Text,
    -- | **REQUIRED.** The schema definition, in the given format.
    _multiFormatSchemaSchema :: Value,
    -- | Specification extensions (@x-@).
    _multiFormatSchemaExtensions :: InsOrdHashMap Text Value
  }
  deriving (Eq, Show, Generic)

instance ToJSON MultiFormatSchema where
  toJSON = jsonViaEncoding
  toEncoding MultiFormatSchema {..} =
    recordEncoding
      _multiFormatSchemaExtensions
      [ "schemaFormat" .=? Just _multiFormatSchemaSchemaFormat,
        "schema" .=? Just _multiFormatSchemaSchema
      ]

instance FromJSON MultiFormatSchema where
  parseJSON = withObject "MultiFormatSchema" $ \o -> do
    _multiFormatSchemaSchemaFormat <- o .: "schemaFormat"
    _multiFormatSchemaSchema <- o .: "schema"
    let _multiFormatSchemaExtensions = parseExtensions o
    pure MultiFormatSchema {..}

-- | A 'MultiFormatSchema' with only the required fields set.
emptyMultiFormatSchema :: Text -> Value -> MultiFormatSchema
emptyMultiFormatSchema fmt schema =
  MultiFormatSchema
    { _multiFormatSchemaSchemaFormat = fmt,
      _multiFormatSchemaSchema = schema,
      _multiFormatSchemaExtensions = InsOrd.empty
    }

-- $ components
--
-- [AsyncAPI 3.1.0 — Components Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#componentsObject)

-- | Reusable objects for different aspects of the specification.
--
-- [AsyncAPI 3.1.0 — Components Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#componentsObject)
data Components = Components
  { -- | Reusable schemas (Schema Objects, references, or other formats).
    -- [Components Object, schemas](https://www.asyncapi.com/docs/reference/specification/v3.1.0#componentsSchemas)
    _componentsSchemas :: Maybe (InsOrdHashMap Text SchemaDefinition),
    -- | Reusable servers.
    -- [Components Object, servers](https://www.asyncapi.com/docs/reference/specification/v3.1.0#componentsServers)
    _componentsServers :: Maybe Servers,
    -- | Reusable channels.
    -- [Components Object, channels](https://www.asyncapi.com/docs/reference/specification/v3.1.0#componentsChannels)
    _componentsChannels :: Maybe Channels,
    -- | Reusable operations.
    -- [Components Object, operations](https://www.asyncapi.com/docs/reference/specification/v3.1.0#componentsOperations)
    _componentsOperations :: Maybe Operations,
    -- | Reusable messages.
    -- [Components Object, messages](https://www.asyncapi.com/docs/reference/specification/v3.1.0#componentsMessages)
    _componentsMessages :: Maybe Messages,
    -- | Reusable security schemes.
    -- [Components Object, securitySchemes](https://www.asyncapi.com/docs/reference/specification/v3.1.0#componentsSecuritySchemes)
    _componentsSecuritySchemes :: Maybe (InsOrdHashMap Text (Referenced SecurityScheme)),
    -- | Reusable server variables.
    -- [Components Object, serverVariables](https://www.asyncapi.com/docs/reference/specification/v3.1.0#componentsServerVariables)
    _componentsServerVariables :: Maybe (InsOrdHashMap Text (Referenced ServerVariable)),
    -- | Reusable parameters.
    -- [Components Object, parameters](https://www.asyncapi.com/docs/reference/specification/v3.1.0#componentsParameters)
    _componentsParameters :: Maybe Parameters,
    -- | Reusable correlation IDs.
    -- [Components Object, correlationIds](https://www.asyncapi.com/docs/reference/specification/v3.1.0#componentsCorrelationIDs)
    _componentsCorrelationIds :: Maybe (InsOrdHashMap Text (Referenced CorrelationId)),
    -- | Reusable operation replies.
    -- [Components Object, replies](https://www.asyncapi.com/docs/reference/specification/v3.1.0#componentsReplies)
    _componentsReplies :: Maybe (InsOrdHashMap Text (Referenced OperationReply)),
    -- | Reusable operation reply addresses.
    -- [Components Object, replyAddresses](https://www.asyncapi.com/docs/reference/specification/v3.1.0#componentsReplyAddresses)
    _componentsReplyAddresses :: Maybe (InsOrdHashMap Text (Referenced OperationReplyAddress)),
    -- | Reusable external documentation objects.
    -- [Components Object, externalDocs](https://www.asyncapi.com/docs/reference/specification/v3.1.0#componentsExternalDocs)
    _componentsExternalDocs :: Maybe (InsOrdHashMap Text (Referenced ExternalDocumentation)),
    -- | Reusable tags.
    -- [Components Object, tags](https://www.asyncapi.com/docs/reference/specification/v3.1.0#componentsTags)
    _componentsTags :: Maybe (InsOrdHashMap Text (Referenced Tag)),
    -- | Reusable operation traits.
    -- [Components Object, operationTraits](https://www.asyncapi.com/docs/reference/specification/v3.1.0#componentsOperationTraits)
    _componentsOperationTraits :: Maybe (InsOrdHashMap Text (Referenced OperationTrait)),
    -- | Reusable message traits.
    -- [Components Object, messageTraits](https://www.asyncapi.com/docs/reference/specification/v3.1.0#componentsMessageTraits)
    _componentsMessageTraits :: Maybe (InsOrdHashMap Text (Referenced MessageTrait)),
    -- | Reusable server bindings.
    -- [Components Object, serverBindings](https://www.asyncapi.com/docs/reference/specification/v3.1.0#componentsServerBindings)
    _componentsServerBindings :: Maybe (InsOrdHashMap Text (Referenced ServerBindings)),
    -- | Reusable channel bindings.
    -- [Components Object, channelBindings](https://www.asyncapi.com/docs/reference/specification/v3.1.0#componentsChannelBindings)
    _componentsChannelBindings :: Maybe (InsOrdHashMap Text (Referenced ChannelBindings)),
    -- | Reusable operation bindings.
    -- [Components Object, operationBindings](https://www.asyncapi.com/docs/reference/specification/v3.1.0#componentsOperationBindings)
    _componentsOperationBindings :: Maybe (InsOrdHashMap Text (Referenced OperationBindings)),
    -- | Reusable message bindings.
    -- [Components Object, messageBindings](https://www.asyncapi.com/docs/reference/specification/v3.1.0#componentsMessageBindings)
    _componentsMessageBindings :: Maybe (InsOrdHashMap Text (Referenced MessageBindings)),
    -- | Specification extensions (@x-@).
    _componentsExtensions :: InsOrdHashMap Text Value
  }
  deriving (Eq, Show, Generic)

-- | A 'Components' object with no reusable objects.
emptyComponents :: Components
emptyComponents =
  Components
    { _componentsSchemas = Nothing,
      _componentsServers = Nothing,
      _componentsChannels = Nothing,
      _componentsOperations = Nothing,
      _componentsMessages = Nothing,
      _componentsSecuritySchemes = Nothing,
      _componentsServerVariables = Nothing,
      _componentsParameters = Nothing,
      _componentsCorrelationIds = Nothing,
      _componentsReplies = Nothing,
      _componentsReplyAddresses = Nothing,
      _componentsExternalDocs = Nothing,
      _componentsTags = Nothing,
      _componentsOperationTraits = Nothing,
      _componentsMessageTraits = Nothing,
      _componentsServerBindings = Nothing,
      _componentsChannelBindings = Nothing,
      _componentsOperationBindings = Nothing,
      _componentsMessageBindings = Nothing,
      _componentsExtensions = InsOrd.empty
    }

instance ToJSON Components where
  toJSON = jsonViaEncoding
  toEncoding Components {..} =
    recordEncoding
      _componentsExtensions
      [ "schemas" .=? fmap SortedObject _componentsSchemas,
        "servers" .=? fmap SortedObject _componentsServers,
        "channels" .=? fmap SortedObject _componentsChannels,
        "operations" .=? fmap SortedObject _componentsOperations,
        "messages" .=? fmap SortedObject _componentsMessages,
        "securitySchemes" .=? fmap SortedObject _componentsSecuritySchemes,
        "serverVariables" .=? fmap SortedObject _componentsServerVariables,
        "parameters" .=? fmap SortedObject _componentsParameters,
        "correlationIds" .=? fmap SortedObject _componentsCorrelationIds,
        "replies" .=? fmap SortedObject _componentsReplies,
        "replyAddresses" .=? fmap SortedObject _componentsReplyAddresses,
        "externalDocs" .=? fmap SortedObject _componentsExternalDocs,
        "tags" .=? fmap SortedObject _componentsTags,
        "operationTraits" .=? fmap SortedObject _componentsOperationTraits,
        "messageTraits" .=? fmap SortedObject _componentsMessageTraits,
        "serverBindings" .=? fmap SortedObject _componentsServerBindings,
        "channelBindings" .=? fmap SortedObject _componentsChannelBindings,
        "operationBindings" .=? fmap SortedObject _componentsOperationBindings,
        "messageBindings" .=? fmap SortedObject _componentsMessageBindings
      ]

instance FromJSON Components where
  parseJSON = withObject "Components" $ \o -> do
    _componentsSchemas <- sortedMapField "schemas" o
    _componentsServers <- sortedMapField "servers" o
    _componentsChannels <- sortedMapField "channels" o
    _componentsOperations <- sortedMapField "operations" o
    _componentsMessages <- sortedMapField "messages" o
    _componentsSecuritySchemes <- sortedMapField "securitySchemes" o
    _componentsServerVariables <- sortedMapField "serverVariables" o
    _componentsParameters <- sortedMapField "parameters" o
    _componentsCorrelationIds <- sortedMapField "correlationIds" o
    _componentsReplies <- sortedMapField "replies" o
    _componentsReplyAddresses <- sortedMapField "replyAddresses" o
    _componentsExternalDocs <- sortedMapField "externalDocs" o
    _componentsTags <- sortedMapField "tags" o
    _componentsOperationTraits <- sortedMapField "operationTraits" o
    _componentsMessageTraits <- sortedMapField "messageTraits" o
    _componentsServerBindings <- sortedMapField "serverBindings" o
    _componentsChannelBindings <- sortedMapField "channelBindings" o
    _componentsOperationBindings <- sortedMapField "operationBindings" o
    _componentsMessageBindings <- sortedMapField "messageBindings" o
    let _componentsExtensions = parseExtensions o
    pure Components {..}

-- $ messages
--
-- [AsyncAPI 3.1.0 — Messages Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#messagesObject)

-- | A map of message identifiers to (possibly referenced) messages.
--
-- [AsyncAPI 3.1.0 — Messages Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#messagesObject)
type Messages = InsOrdHashMap Text (Referenced Message)

-- | A schema definition in any supported form: a (possibly referenced)
-- Schema Object, or a Multi Format Schema Object for other formats.
--
-- [Multi Format Schema Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#multiFormatSchemaObject)
data SchemaDefinition
  = -- | A Schema Object or a Reference to one.
    SchemaDefSchema (Referenced Schema)
  | -- | A schema in another format (e.g. Avro).
    SchemaDefMultiFormat MultiFormatSchema
  deriving (Eq, Show, Generic)

instance ToJSON SchemaDefinition where
  toJSON = jsonViaEncoding
  toEncoding (SchemaDefMultiFormat m) = toEncoding m
  toEncoding (SchemaDefSchema s) = toEncoding s

instance FromJSON SchemaDefinition where
  parseJSON v@(Object o)
    -- `schemaFormat` is REQUIRED in the Multi Format Schema Object and is not
    -- a draft-07 keyword, so its presence alone is an unambiguous
    -- discriminator; a missing `schema` then fails inside MultiFormatSchema
    -- (naming the real problem) instead of decoding as an empty schema.
    | KM.member "schemaFormat" o = SchemaDefMultiFormat <$> parseJSON v
  parseJSON v = SchemaDefSchema <$> parseJSON v

-- | A message received on a given channel and operation.
--
-- [AsyncAPI 3.1.0 — Message Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#messageObject)
data Message = Message
  { -- | Schema definition of the application headers.
    _messageHeaders :: Maybe SchemaDefinition,
    -- | Definition of the message payload.
    _messagePayload :: Maybe SchemaDefinition,
    -- | Definition of the correlation ID used for message tracing or matching.
    -- [Correlation ID Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#correlationIdObject)
    _messageCorrelationId :: Maybe (Referenced CorrelationId),
    -- | The content type to use when encoding\/decoding the payload.
    -- [Message Object, contentType](https://www.asyncapi.com/docs/reference/specification/v3.1.0#messageObjectContentType)
    _messageContentType :: Maybe ContentType,
    -- | A machine-friendly name for the message.
    _messageName :: Maybe Name,
    -- | A human-friendly title for the message.
    _messageTitle :: Maybe Title,
    -- | A short summary of what the message is about.
    _messageSummary :: Maybe Summary,
    -- | A verbose explanation of the message.
    _messageDescription :: Maybe Description,
    -- | A list of tags for logical grouping of messages.
    _messageTags :: Maybe Tags,
    -- | Additional external documentation for this message.
    _messageExternalDocs :: Maybe (Referenced ExternalDocumentation),
    -- | Protocol-specific definitions for the message.
    -- [Message Bindings Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#messageBindingsObject)
    _messageBindings :: Maybe (Referenced MessageBindings),
    -- | List of examples.
    -- [Message Example Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#messageExampleObject)
    _messageExamples :: Maybe [MessageExample],
    -- | A list of traits to apply to the message object.
    -- [Message Trait Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#messageTraitObject)
    _messageTraits :: Maybe [Referenced MessageTrait],
    -- | Specification extensions (@x-@).
    _messageExtensions :: InsOrdHashMap Text Value
  }
  deriving (Eq, Show, Generic)

instance ToJSON Message where
  toJSON = jsonViaEncoding
  toEncoding Message {..} =
    recordEncoding
      _messageExtensions
      [ "headers" .=? _messageHeaders,
        "payload" .=? _messagePayload,
        "correlationId" .=? _messageCorrelationId,
        "contentType" .=? _messageContentType,
        "name" .=? _messageName,
        "title" .=? _messageTitle,
        "summary" .=? _messageSummary,
        "description" .=? _messageDescription,
        "tags" .=? _messageTags,
        "externalDocs" .=? _messageExternalDocs,
        "bindings" .=? _messageBindings,
        "examples" .=? _messageExamples,
        "traits" .=? _messageTraits
      ]

instance FromJSON Message where
  parseJSON = withObject "Message" $ \o -> do
    _messageHeaders <- o .:? "headers"
    _messagePayload <- o .:? "payload"
    _messageCorrelationId <- o .:? "correlationId"
    _messageContentType <- o .:? "contentType"
    _messageName <- o .:? "name"
    _messageTitle <- o .:? "title"
    _messageSummary <- o .:? "summary"
    _messageDescription <- o .:? "description"
    _messageTags <- o .:? "tags"
    _messageExternalDocs <- o .:? "externalDocs"
    _messageBindings <- o .:? "bindings"
    _messageExamples <- o .:? "examples"
    _messageTraits <- o .:? "traits"
    let _messageExtensions = parseExtensions o
    pure Message {..}

-- | A 'Message' with only the required fields set.
emptyMessage :: Message
emptyMessage =
  Message
    { _messageHeaders = Nothing,
      _messagePayload = Nothing,
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

-- | A trait that MAY be applied to a message; any Message Object property
-- except @payload@ and @traits@.
--
-- [AsyncAPI 3.1.0 — Message Trait Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#messageTraitObject)
data MessageTrait = MessageTrait
  { -- | Schema definition of the application headers.
    _messageTraitHeaders :: Maybe SchemaDefinition,
    -- | Definition of the correlation ID.
    _messageTraitCorrelationId :: Maybe (Referenced CorrelationId),
    -- | The content type to use when encoding\/decoding the payload.
    _messageTraitContentType :: Maybe ContentType,
    -- | A machine-friendly name for the message.
    _messageTraitName :: Maybe Name,
    -- | A human-friendly title for the message.
    _messageTraitTitle :: Maybe Title,
    -- | A short summary of what the message is about.
    _messageTraitSummary :: Maybe Summary,
    -- | A verbose explanation of the message.
    _messageTraitDescription :: Maybe Description,
    -- | A list of tags for logical grouping of messages.
    _messageTraitTags :: Maybe Tags,
    -- | Additional external documentation for this message.
    _messageTraitExternalDocs :: Maybe (Referenced ExternalDocumentation),
    -- | Protocol-specific definitions for the message.
    _messageTraitBindings :: Maybe (Referenced MessageBindings),
    -- | List of examples.
    _messageTraitExamples :: Maybe [MessageExample],
    -- | Specification extensions (@x-@).
    _messageTraitExtensions :: InsOrdHashMap Text Value
  }
  deriving (Eq, Show, Generic)

instance ToJSON MessageTrait where
  toJSON = jsonViaEncoding
  toEncoding MessageTrait {..} =
    recordEncoding
      _messageTraitExtensions
      [ "headers" .=? _messageTraitHeaders,
        "correlationId" .=? _messageTraitCorrelationId,
        "contentType" .=? _messageTraitContentType,
        "name" .=? _messageTraitName,
        "title" .=? _messageTraitTitle,
        "summary" .=? _messageTraitSummary,
        "description" .=? _messageTraitDescription,
        "tags" .=? _messageTraitTags,
        "externalDocs" .=? _messageTraitExternalDocs,
        "bindings" .=? _messageTraitBindings,
        "examples" .=? _messageTraitExamples
      ]

instance FromJSON MessageTrait where
  parseJSON = withObject "MessageTrait" $ \o -> do
    _messageTraitHeaders <- o .:? "headers"
    _messageTraitCorrelationId <- o .:? "correlationId"
    _messageTraitContentType <- o .:? "contentType"
    _messageTraitName <- o .:? "name"
    _messageTraitTitle <- o .:? "title"
    _messageTraitSummary <- o .:? "summary"
    _messageTraitDescription <- o .:? "description"
    _messageTraitTags <- o .:? "tags"
    _messageTraitExternalDocs <- o .:? "externalDocs"
    _messageTraitBindings <- o .:? "bindings"
    _messageTraitExamples <- o .:? "examples"
    let _messageTraitExtensions = parseExtensions o
    pure MessageTrait {..}

-- | A 'MessageTrait' with only the required fields set.
emptyMessageTrait :: MessageTrait
emptyMessageTrait =
  MessageTrait
    { _messageTraitHeaders = Nothing,
      _messageTraitCorrelationId = Nothing,
      _messageTraitContentType = Nothing,
      _messageTraitName = Nothing,
      _messageTraitTitle = Nothing,
      _messageTraitSummary = Nothing,
      _messageTraitDescription = Nothing,
      _messageTraitTags = Nothing,
      _messageTraitExternalDocs = Nothing,
      _messageTraitBindings = Nothing,
      _messageTraitExamples = Nothing,
      _messageTraitExtensions = InsOrd.empty
    }

-- | An example of a message; MUST contain headers and\/or payload.
--
-- [AsyncAPI 3.1.0 — Message Example Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#messageExampleObject)
data MessageExample = MessageExample
  { -- | Example headers, validating against the message's @headers@.
    _messageExampleHeaders :: Maybe (InsOrdHashMap Text Value),
    -- | Example payload, validating against the message's @payload@.
    _messageExamplePayload :: Maybe Value,
    -- | A machine-friendly name.
    _messageExampleName :: Maybe Name,
    -- | A short summary of what the example is about.
    _messageExampleSummary :: Maybe Summary,
    -- | Specification extensions (@x-@).
    _messageExampleExtensions :: InsOrdHashMap Text Value
  }
  deriving (Eq, Show, Generic)

instance ToJSON MessageExample where
  toJSON = jsonViaEncoding
  toEncoding MessageExample {..} =
    recordEncoding
      _messageExampleExtensions
      [ "headers" .=? fmap SortedObject _messageExampleHeaders,
        "payload" .=? _messageExamplePayload,
        "name" .=? _messageExampleName,
        "summary" .=? _messageExampleSummary
      ]

instance FromJSON MessageExample where
  parseJSON = withObject "MessageExample" $ \o -> do
    _messageExampleHeaders <- sortedMapField "headers" o
    _messageExamplePayload <- o .:? "payload"
    _messageExampleName <- o .:? "name"
    _messageExampleSummary <- o .:? "summary"
    let _messageExampleExtensions = parseExtensions o
    pure MessageExample {..}

-- | A 'MessageExample' with only the required fields set.
emptyMessageExample :: MessageExample
emptyMessageExample =
  MessageExample
    { _messageExampleHeaders = Nothing,
      _messageExamplePayload = Nothing,
      _messageExampleName = Nothing,
      _messageExampleSummary = Nothing,
      _messageExampleExtensions = InsOrd.empty
    }

-- | An identifier used for message tracing and correlation.
--
-- [AsyncAPI 3.1.0 — Correlation ID Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#correlationIdObject)
data CorrelationId = CorrelationId
  { -- | An optional description of the identifier.
    _correlationIdDescription :: Maybe Description,
    -- | **REQUIRED.** A runtime expression locating the correlation ID.
    -- [Runtime Expression](https://www.asyncapi.com/docs/reference/specification/v3.1.0#runtimeExpression)
    _correlationIdLocation :: RuntimeExpression,
    -- | Specification extensions (@x-@).
    _correlationIdExtensions :: InsOrdHashMap Text Value
  }
  deriving (Eq, Show, Generic)

instance ToJSON CorrelationId where
  toJSON = jsonViaEncoding
  toEncoding CorrelationId {..} =
    recordEncoding
      _correlationIdExtensions
      [ "description" .=? _correlationIdDescription,
        "location" .=? Just _correlationIdLocation
      ]

instance FromJSON CorrelationId where
  parseJSON = withObject "CorrelationId" $ \o -> do
    _correlationIdDescription <- o .:? "description"
    _correlationIdLocation <- o .: "location"
    let _correlationIdExtensions = parseExtensions o
    pure CorrelationId {..}

-- | A 'CorrelationId' with only the required fields set.
emptyCorrelationId :: RuntimeExpression -> CorrelationId
emptyCorrelationId loc =
  CorrelationId
    { _correlationIdDescription = Nothing,
      _correlationIdLocation = loc,
      _correlationIdExtensions = InsOrd.empty
    }

-- $ operations
--
-- [AsyncAPI 3.1.0 — Operations Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#operationsObject)

-- | A map of operation identifiers to (possibly referenced) operations.
--
-- [AsyncAPI 3.1.0 — Operations Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#operationsObject)
type Operations = InsOrdHashMap Text (Referenced Operation)

-- | The direction of an operation.
--
-- [Operation Object, action](https://www.asyncapi.com/docs/reference/specification/v3.1.0#operationObjectAction)
data OperationAction
  = -- | The application sends a message to the channel.
    Send
  | -- | The application receives messages from the channel.
    Receive
  deriving (Eq, Show, Generic)

instance ToJSON OperationAction where
  toJSON = jsonViaEncoding
  toEncoding a = toEncoding (case a of Send -> "send" :: Text; Receive -> "receive")

instance FromJSON OperationAction where
  parseJSON = withText "OperationAction" $ \case
    "send" -> pure Send
    "receive" -> pure Receive
    t -> fail ("unknown operation action: " <> show t)

-- | A specific operation.
--
-- [AsyncAPI 3.1.0 — Operation Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#operationObject)
data Operation = Operation
  { -- | **REQUIRED.** @send@ or @receive@.
    -- [Operation Object, action](https://www.asyncapi.com/docs/reference/specification/v3.1.0#operationObjectAction)
    _operationAction :: OperationAction,
    -- | **REQUIRED.** A @$ref@ pointer to the channel of this operation; MUST
    -- be a Reference Object.
    -- [Operation Object, channel](https://www.asyncapi.com/docs/reference/specification/v3.1.0#operationObjectChannel)
    _operationChannel :: Reference,
    -- | A human-friendly title for the operation.
    _operationTitle :: Maybe Title,
    -- | A short summary of what the operation is about.
    _operationSummary :: Maybe Summary,
    -- | A verbose explanation of the operation.
    _operationDescription :: Maybe Description,
    -- | A declaration of which security schemes are associated with this
    -- operation.
    -- [Security Scheme Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#securitySchemeObject)
    _operationSecurity :: Maybe [Referenced SecurityScheme],
    -- | A list of tags for logical grouping of operations.
    _operationTags :: Maybe Tags,
    -- | Additional external documentation for this operation.
    _operationExternalDocs :: Maybe (Referenced ExternalDocumentation),
    -- | Protocol-specific definitions for the operation.
    -- [Operation Bindings Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#operationBindingsObject)
    _operationBindings :: Maybe (Referenced OperationBindings),
    -- | A list of traits to apply to the operation object.
    -- [Operation Trait Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#operationTraitObject)
    _operationTraits :: Maybe [Referenced OperationTrait],
    -- | References to the supported messages of this operation; MUST be a
    -- list of Reference Objects.
    -- [Operation Object, messages](https://www.asyncapi.com/docs/reference/specification/v3.1.0#operationObjectMessages)
    _operationMessages :: Maybe [Reference],
    -- | The definition of the reply in a request-reply operation.
    -- [Operation Reply Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#operationReplyObject)
    _operationReply :: Maybe (Referenced OperationReply),
    -- | Specification extensions (@x-@).
    _operationExtensions :: InsOrdHashMap Text Value
  }
  deriving (Eq, Show, Generic)

instance ToJSON Operation where
  toJSON = jsonViaEncoding
  toEncoding Operation {..} =
    recordEncoding
      _operationExtensions
      [ "action" .=? Just _operationAction,
        "channel" .=? Just _operationChannel,
        "title" .=? _operationTitle,
        "summary" .=? _operationSummary,
        "description" .=? _operationDescription,
        "security" .=? _operationSecurity,
        "tags" .=? _operationTags,
        "externalDocs" .=? _operationExternalDocs,
        "bindings" .=? _operationBindings,
        "traits" .=? _operationTraits,
        "messages" .=? _operationMessages,
        "reply" .=? _operationReply
      ]

instance FromJSON Operation where
  parseJSON = withObject "Operation" $ \o -> do
    _operationAction <- o .: "action"
    _operationChannel <- o .: "channel"
    _operationTitle <- o .:? "title"
    _operationSummary <- o .:? "summary"
    _operationDescription <- o .:? "description"
    _operationSecurity <- o .:? "security"
    _operationTags <- o .:? "tags"
    _operationExternalDocs <- o .:? "externalDocs"
    _operationBindings <- o .:? "bindings"
    _operationTraits <- o .:? "traits"
    _operationMessages <- o .:? "messages"
    _operationReply <- o .:? "reply"
    let _operationExtensions = parseExtensions o
    pure Operation {..}

-- | An 'Operation' with only the required fields set.
emptyOperation :: OperationAction -> Reference -> Operation
emptyOperation action channel =
  Operation
    { _operationAction = action,
      _operationChannel = channel,
      _operationTitle = Nothing,
      _operationSummary = Nothing,
      _operationDescription = Nothing,
      _operationSecurity = Nothing,
      _operationTags = Nothing,
      _operationExternalDocs = Nothing,
      _operationBindings = Nothing,
      _operationTraits = Nothing,
      _operationMessages = Nothing,
      _operationReply = Nothing,
      _operationExtensions = InsOrd.empty
    }

-- | A trait that MAY be applied to an operation; any Operation Object
-- property except @action@, @channel@, @messages@ and @traits@.
--
-- [AsyncAPI 3.1.0 — Operation Trait Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#operationTraitObject)
data OperationTrait = OperationTrait
  { -- | A human-friendly title for the operation.
    _operationTraitTitle :: Maybe Title,
    -- | A short summary of what the operation is about.
    _operationTraitSummary :: Maybe Summary,
    -- | A verbose explanation of the operation.
    _operationTraitDescription :: Maybe Description,
    -- | A declaration of which security schemes are associated with this
    -- operation.
    _operationTraitSecurity :: Maybe [Referenced SecurityScheme],
    -- | A list of tags for logical grouping of operations.
    _operationTraitTags :: Maybe Tags,
    -- | Additional external documentation for this operation.
    _operationTraitExternalDocs :: Maybe (Referenced ExternalDocumentation),
    -- | Protocol-specific definitions for the operation.
    _operationTraitBindings :: Maybe (Referenced OperationBindings),
    -- | Specification extensions (@x-@).
    _operationTraitExtensions :: InsOrdHashMap Text Value
  }
  deriving (Eq, Show, Generic)

instance ToJSON OperationTrait where
  toJSON = jsonViaEncoding
  toEncoding OperationTrait {..} =
    recordEncoding
      _operationTraitExtensions
      [ "title" .=? _operationTraitTitle,
        "summary" .=? _operationTraitSummary,
        "description" .=? _operationTraitDescription,
        "security" .=? _operationTraitSecurity,
        "tags" .=? _operationTraitTags,
        "externalDocs" .=? _operationTraitExternalDocs,
        "bindings" .=? _operationTraitBindings
      ]

instance FromJSON OperationTrait where
  parseJSON = withObject "OperationTrait" $ \o -> do
    _operationTraitTitle <- o .:? "title"
    _operationTraitSummary <- o .:? "summary"
    _operationTraitDescription <- o .:? "description"
    _operationTraitSecurity <- o .:? "security"
    _operationTraitTags <- o .:? "tags"
    _operationTraitExternalDocs <- o .:? "externalDocs"
    _operationTraitBindings <- o .:? "bindings"
    let _operationTraitExtensions = parseExtensions o
    pure OperationTrait {..}

-- | An 'OperationTrait' with only the required fields set.
emptyOperationTrait :: OperationTrait
emptyOperationTrait =
  OperationTrait
    { _operationTraitTitle = Nothing,
      _operationTraitSummary = Nothing,
      _operationTraitDescription = Nothing,
      _operationTraitSecurity = Nothing,
      _operationTraitTags = Nothing,
      _operationTraitExternalDocs = Nothing,
      _operationTraitBindings = Nothing,
      _operationTraitExtensions = InsOrd.empty
    }

-- | The reply part of a request-reply operation.
--
-- [AsyncAPI 3.1.0 — Operation Reply Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#operationReplyObject)
data OperationReply = OperationReply
  { -- | The address implementations MUST use for the reply.
    -- [Operation Reply Address Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#operationReplyAddressObject)
    _operationReplyAddress :: Maybe (Referenced OperationReplyAddress),
    -- | A @$ref@ pointer to the reply channel; MUST be a Reference Object.
    _operationReplyChannel :: Maybe Reference,
    -- | References to the supported reply messages; MUST be a list of
    -- Reference Objects.
    _operationReplyMessages :: Maybe [Reference],
    -- | Specification extensions (@x-@).
    _operationReplyExtensions :: InsOrdHashMap Text Value
  }
  deriving (Eq, Show, Generic)

instance ToJSON OperationReply where
  toJSON = jsonViaEncoding
  toEncoding OperationReply {..} =
    recordEncoding
      _operationReplyExtensions
      [ "address" .=? _operationReplyAddress,
        "channel" .=? _operationReplyChannel,
        "messages" .=? _operationReplyMessages
      ]

instance FromJSON OperationReply where
  parseJSON = withObject "OperationReply" $ \o -> do
    _operationReplyAddress <- o .:? "address"
    _operationReplyChannel <- o .:? "channel"
    _operationReplyMessages <- o .:? "messages"
    let _operationReplyExtensions = parseExtensions o
    pure OperationReply {..}

-- | An 'OperationReply' with only the required fields set.
emptyOperationReply :: OperationReply
emptyOperationReply =
  OperationReply
    { _operationReplyAddress = Nothing,
      _operationReplyChannel = Nothing,
      _operationReplyMessages = Nothing,
      _operationReplyExtensions = InsOrd.empty
    }

-- | Where an operation has to send the reply, as a runtime expression.
--
-- [AsyncAPI 3.1.0 — Operation Reply Address Object](https://www.asyncapi.com/docs/reference/specification/v3.1.0#operationReplyAddressObject)
data OperationReplyAddress = OperationReplyAddress
  { -- | An optional description of the address.
    _operationReplyAddressDescription :: Maybe Description,
    -- | **REQUIRED.** A runtime expression specifying the reply location.
    -- [Runtime Expression](https://www.asyncapi.com/docs/reference/specification/v3.1.0#runtimeExpression)
    _operationReplyAddressLocation :: RuntimeExpression,
    -- | Specification extensions (@x-@).
    _operationReplyAddressExtensions :: InsOrdHashMap Text Value
  }
  deriving (Eq, Show, Generic)

instance ToJSON OperationReplyAddress where
  toJSON = jsonViaEncoding
  toEncoding OperationReplyAddress {..} =
    recordEncoding
      _operationReplyAddressExtensions
      [ "description" .=? _operationReplyAddressDescription,
        "location" .=? Just _operationReplyAddressLocation
      ]

instance FromJSON OperationReplyAddress where
  parseJSON = withObject "OperationReplyAddress" $ \o -> do
    _operationReplyAddressDescription <- o .:? "description"
    _operationReplyAddressLocation <- o .: "location"
    let _operationReplyAddressExtensions = parseExtensions o
    pure OperationReplyAddress {..}

-- | An 'OperationReplyAddress' with only the required fields set.
emptyOperationReplyAddress :: RuntimeExpression -> OperationReplyAddress
emptyOperationReplyAddress loc =
  OperationReplyAddress
    { _operationReplyAddressDescription = Nothing,
      _operationReplyAddressLocation = loc,
      _operationReplyAddressExtensions = InsOrd.empty
    }
