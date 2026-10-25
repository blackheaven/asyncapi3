{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE UndecidableInstances #-}

-- | Field lenses and prisms for the AsyncAPI 3.1.0 model, built with
-- @lens@. Generated field lenses are named after the JSON keys (e.g.
-- @title@ on both 'Info' and 'Message').
--
-- Four records contain fields whose JSON keys are Haskell keywords
-- (@type@, @if@, @then@, @else@, @default@, @in@); they cannot use
-- 'makeFields' (the method name would be a keyword), so their fields get
-- explicit type-prefixed lenses instead: @schemaObj*@, @serverVariable*@,
-- @parameter*@, @securityScheme*@ (no underscores).
module Data.AsyncAPI.Lens
  ( module Data.AsyncAPI.Lens,
    module Data.AsyncAPI.Internal,
    module Data.AsyncAPI.Internal.Schema,
  )
where

import Control.Lens (Lens', lens)
import Control.Lens.TH (makeFields, makePrisms)
import Data.Aeson (Value)
import Data.AsyncAPI.Internal
import Data.AsyncAPI.Internal.Schema
import Data.HashMap.Strict.InsOrd (InsOrdHashMap)
import Data.Scientific (Scientific)
import Data.Text (Text)

-- Root
makeFields ''AsyncAPI
makeFields ''Info
makeFields ''Contact
makeFields ''License
makeFields ''Server
makeFields ''Channel
makeFields ''Tag
makeFields ''ExternalDocumentation
makeFields ''Reference
makeFields ''Components

-- Security (type/in are keywords; explicit lenses below)
makeFields ''OAuthFlows
makeFields ''OAuthFlow

-- Bindings
makeFields ''ServerBindings
makeFields ''ChannelBindings
makeFields ''OperationBindings
makeFields ''MessageBindings

-- Schemas (type/if/then/else/default are keywords; explicit lenses below)
makeFields ''MultiFormatSchema

-- Messages
makeFields ''Message
makeFields ''MessageTrait
makeFields ''MessageExample
makeFields ''CorrelationId

-- Operations
makeFields ''Operation
makeFields ''OperationTrait
makeFields ''OperationReply
makeFields ''OperationReplyAddress

-- Prisms for sum types
makePrisms ''Referenced
makePrisms ''Schema
makePrisms ''SchemaType
makePrisms ''ItemsSchema
makePrisms ''AdditionalProperties
makePrisms ''SchemaDefinition
makePrisms ''SecuritySchemeType
makePrisms ''ApiKeyLocation
makePrisms ''OperationAction
makePrisms ''JsonType

-- Schema Object lenses
schemaObjTitle :: Lens' SchemaObj (Maybe Title)
schemaObjTitle = lens _schemaTitle (\s a -> s {_schemaTitle = a})

schemaObjType :: Lens' SchemaObj (Maybe SchemaType)
schemaObjType = lens _schemaType (\s a -> s {_schemaType = a})

schemaObjRequired :: Lens' SchemaObj (Maybe [Text])
schemaObjRequired = lens _schemaRequired (\s a -> s {_schemaRequired = a})

schemaObjMultipleOf :: Lens' SchemaObj (Maybe Scientific)
schemaObjMultipleOf = lens _schemaMultipleOf (\s a -> s {_schemaMultipleOf = a})

schemaObjMaximum :: Lens' SchemaObj (Maybe Scientific)
schemaObjMaximum = lens _schemaMaximum (\s a -> s {_schemaMaximum = a})

schemaObjExclusiveMaximum :: Lens' SchemaObj (Maybe Scientific)
schemaObjExclusiveMaximum = lens _schemaExclusiveMaximum (\s a -> s {_schemaExclusiveMaximum = a})

schemaObjMinimum :: Lens' SchemaObj (Maybe Scientific)
schemaObjMinimum = lens _schemaMinimum (\s a -> s {_schemaMinimum = a})

schemaObjExclusiveMinimum :: Lens' SchemaObj (Maybe Scientific)
schemaObjExclusiveMinimum = lens _schemaExclusiveMinimum (\s a -> s {_schemaExclusiveMinimum = a})

schemaObjMaxLength :: Lens' SchemaObj (Maybe Int)
schemaObjMaxLength = lens _schemaMaxLength (\s a -> s {_schemaMaxLength = a})

schemaObjMinLength :: Lens' SchemaObj (Maybe Int)
schemaObjMinLength = lens _schemaMinLength (\s a -> s {_schemaMinLength = a})

schemaObjPattern :: Lens' SchemaObj (Maybe Text)
schemaObjPattern = lens _schemaPattern (\s a -> s {_schemaPattern = a})

schemaObjMaxItems :: Lens' SchemaObj (Maybe Int)
schemaObjMaxItems = lens _schemaMaxItems (\s a -> s {_schemaMaxItems = a})

schemaObjMinItems :: Lens' SchemaObj (Maybe Int)
schemaObjMinItems = lens _schemaMinItems (\s a -> s {_schemaMinItems = a})

schemaObjUniqueItems :: Lens' SchemaObj (Maybe Bool)
schemaObjUniqueItems = lens _schemaUniqueItems (\s a -> s {_schemaUniqueItems = a})

schemaObjMaxProperties :: Lens' SchemaObj (Maybe Int)
schemaObjMaxProperties = lens _schemaMaxProperties (\s a -> s {_schemaMaxProperties = a})

schemaObjMinProperties :: Lens' SchemaObj (Maybe Int)
schemaObjMinProperties = lens _schemaMinProperties (\s a -> s {_schemaMinProperties = a})

schemaObjEnum :: Lens' SchemaObj (Maybe [Value])
schemaObjEnum = lens _schemaEnum (\s a -> s {_schemaEnum = a})

schemaObjConst :: Lens' SchemaObj (Maybe Value)
schemaObjConst = lens _schemaConst (\s a -> s {_schemaConst = a})

schemaObjExamples :: Lens' SchemaObj (Maybe [Value])
schemaObjExamples = lens _schemaExamples (\s a -> s {_schemaExamples = a})

schemaObjIf :: Lens' SchemaObj (Maybe (Referenced Schema))
schemaObjIf = lens _schemaIf (\s a -> s {_schemaIf = a})

schemaObjThen :: Lens' SchemaObj (Maybe (Referenced Schema))
schemaObjThen = lens _schemaThen (\s a -> s {_schemaThen = a})

schemaObjElse :: Lens' SchemaObj (Maybe (Referenced Schema))
schemaObjElse = lens _schemaElse (\s a -> s {_schemaElse = a})

schemaObjReadOnly :: Lens' SchemaObj (Maybe Bool)
schemaObjReadOnly = lens _schemaReadOnly (\s a -> s {_schemaReadOnly = a})

schemaObjWriteOnly :: Lens' SchemaObj (Maybe Bool)
schemaObjWriteOnly = lens _schemaWriteOnly (\s a -> s {_schemaWriteOnly = a})

schemaObjProperties :: Lens' SchemaObj (Maybe (InsOrdHashMap Text (Referenced Schema)))
schemaObjProperties = lens _schemaProperties (\s a -> s {_schemaProperties = a})

schemaObjPatternProperties :: Lens' SchemaObj (Maybe (InsOrdHashMap Text (Referenced Schema)))
schemaObjPatternProperties = lens _schemaPatternProperties (\s a -> s {_schemaPatternProperties = a})

schemaObjAdditionalProperties :: Lens' SchemaObj (Maybe AdditionalProperties)
schemaObjAdditionalProperties = lens _schemaAdditionalProperties (\s a -> s {_schemaAdditionalProperties = a})

schemaObjAdditionalItems :: Lens' SchemaObj (Maybe AdditionalProperties)
schemaObjAdditionalItems = lens _schemaAdditionalItems (\s a -> s {_schemaAdditionalItems = a})

schemaObjItems :: Lens' SchemaObj (Maybe ItemsSchema)
schemaObjItems = lens _schemaItems (\s a -> s {_schemaItems = a})

schemaObjPropertyNames :: Lens' SchemaObj (Maybe (Referenced Schema))
schemaObjPropertyNames = lens _schemaPropertyNames (\s a -> s {_schemaPropertyNames = a})

schemaObjContains :: Lens' SchemaObj (Maybe (Referenced Schema))
schemaObjContains = lens _schemaContains (\s a -> s {_schemaContains = a})

schemaObjAllOf :: Lens' SchemaObj (Maybe [Referenced Schema])
schemaObjAllOf = lens _schemaAllOf (\s a -> s {_schemaAllOf = a})

schemaObjOneOf :: Lens' SchemaObj (Maybe [Referenced Schema])
schemaObjOneOf = lens _schemaOneOf (\s a -> s {_schemaOneOf = a})

schemaObjAnyOf :: Lens' SchemaObj (Maybe [Referenced Schema])
schemaObjAnyOf = lens _schemaAnyOf (\s a -> s {_schemaAnyOf = a})

schemaObjNot :: Lens' SchemaObj (Maybe (Referenced Schema))
schemaObjNot = lens _schemaNot (\s a -> s {_schemaNot = a})

schemaObjDescription :: Lens' SchemaObj (Maybe Description)
schemaObjDescription = lens _schemaDescription (\s a -> s {_schemaDescription = a})

schemaObjFormat :: Lens' SchemaObj (Maybe Text)
schemaObjFormat = lens _schemaFormat (\s a -> s {_schemaFormat = a})

schemaObjDefault :: Lens' SchemaObj (Maybe Value)
schemaObjDefault = lens _schemaDefault (\s a -> s {_schemaDefault = a})

schemaObjDiscriminator :: Lens' SchemaObj (Maybe Text)
schemaObjDiscriminator = lens _schemaDiscriminator (\s a -> s {_schemaDiscriminator = a})

schemaObjExternalDocs :: Lens' SchemaObj (Maybe (Referenced ExternalDocumentation))
schemaObjExternalDocs = lens _schemaExternalDocs (\s a -> s {_schemaExternalDocs = a})

schemaObjDeprecated :: Lens' SchemaObj (Maybe Bool)
schemaObjDeprecated = lens _schemaDeprecated (\s a -> s {_schemaDeprecated = a})

-- Server Variable Object lenses
serverVariableEnum :: Lens' ServerVariable (Maybe [Text])
serverVariableEnum = lens _serverVariableEnum (\s a -> s {_serverVariableEnum = a})

serverVariableDefault :: Lens' ServerVariable (Maybe Text)
serverVariableDefault = lens _serverVariableDefault (\s a -> s {_serverVariableDefault = a})

serverVariableDescription :: Lens' ServerVariable (Maybe Description)
serverVariableDescription = lens _serverVariableDescription (\s a -> s {_serverVariableDescription = a})

serverVariableExamples :: Lens' ServerVariable (Maybe [Text])
serverVariableExamples = lens _serverVariableExamples (\s a -> s {_serverVariableExamples = a})

-- Parameter Object lenses
parameterEnum :: Lens' Parameter (Maybe [Text])
parameterEnum = lens _parameterEnum (\s a -> s {_parameterEnum = a})

parameterDefault :: Lens' Parameter (Maybe Text)
parameterDefault = lens _parameterDefault (\s a -> s {_parameterDefault = a})

parameterDescription :: Lens' Parameter (Maybe Description)
parameterDescription = lens _parameterDescription (\s a -> s {_parameterDescription = a})

parameterExamples :: Lens' Parameter (Maybe [Text])
parameterExamples = lens _parameterExamples (\s a -> s {_parameterExamples = a})

parameterLocation :: Lens' Parameter (Maybe RuntimeExpression)
parameterLocation = lens _parameterLocation (\s a -> s {_parameterLocation = a})

-- Security Scheme lenses
securitySchemeType :: Lens' SecurityScheme (SecuritySchemeType)
securitySchemeType = lens _securitySchemeType (\s a -> s {_securitySchemeType = a})

securitySchemeDescription :: Lens' SecurityScheme (Maybe Description)
securitySchemeDescription = lens _securitySchemeDescription (\s a -> s {_securitySchemeDescription = a})

securitySchemeName :: Lens' SecurityScheme (Maybe Name)
securitySchemeName = lens _securitySchemeName (\s a -> s {_securitySchemeName = a})

securitySchemeIn :: Lens' SecurityScheme (Maybe ApiKeyLocation)
securitySchemeIn = lens _securitySchemeIn (\s a -> s {_securitySchemeIn = a})

securitySchemeScheme :: Lens' SecurityScheme (Maybe Text)
securitySchemeScheme = lens _securitySchemeScheme (\s a -> s {_securitySchemeScheme = a})

securitySchemeBearerFormat :: Lens' SecurityScheme (Maybe Text)
securitySchemeBearerFormat = lens _securitySchemeBearerFormat (\s a -> s {_securitySchemeBearerFormat = a})

securitySchemeFlows :: Lens' SecurityScheme (Maybe OAuthFlows)
securitySchemeFlows = lens _securitySchemeFlows (\s a -> s {_securitySchemeFlows = a})

securitySchemeOpenIdConnectUrl :: Lens' SecurityScheme (Maybe Url)
securitySchemeOpenIdConnectUrl = lens _securitySchemeOpenIdConnectUrl (\s a -> s {_securitySchemeOpenIdConnectUrl = a})

securitySchemeScopes :: Lens' SecurityScheme (Maybe [Text])
securitySchemeScopes = lens _securitySchemeScopes (\s a -> s {_securitySchemeScopes = a})
