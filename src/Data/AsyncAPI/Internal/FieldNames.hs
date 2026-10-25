-- | Explicit field-name mappings for records whose JSON keys are Haskell
-- keywords; used with @makeFieldLabelsFor@ by the optics interface.
module Data.AsyncAPI.Internal.FieldNames
  ( parameterFields,
    serverVariableFields,
    schemaObjFields,
  )
where

-- | Parameter Object fields, mapped to label names (@default@ is a Haskell
-- keyword).
parameterFields :: [(String, String)]
parameterFields =
  [ ("_parameterEnum", "enum"),
    ("_parameterDefault", "default_"),
    ("_parameterDescription", "description"),
    ("_parameterExamples", "examples"),
    ("_parameterLocation", "location")
  ]

-- | Server Variable Object fields (@default@ is a Haskell keyword).
serverVariableFields :: [(String, String)]
serverVariableFields =
  [ ("_serverVariableEnum", "enum"),
    ("_serverVariableDefault", "default_"),
    ("_serverVariableDescription", "description"),
    ("_serverVariableExamples", "examples")
  ]

-- | Schema Object fields (@type@, @if@, @then@, @else@ and @default@ are
-- Haskell keywords).
schemaObjFields :: [(String, String)]
schemaObjFields =
  [ ("_schemaTitle", "title"),
    ("_schemaType", "type_"),
    ("_schemaRequired", "required"),
    ("_schemaMultipleOf", "multipleOf"),
    ("_schemaMaximum", "maximum"),
    ("_schemaExclusiveMaximum", "exclusiveMaximum"),
    ("_schemaMinimum", "minimum"),
    ("_schemaExclusiveMinimum", "exclusiveMinimum"),
    ("_schemaMaxLength", "maxLength"),
    ("_schemaMinLength", "minLength"),
    ("_schemaPattern", "pattern"),
    ("_schemaMaxItems", "maxItems"),
    ("_schemaMinItems", "minItems"),
    ("_schemaUniqueItems", "uniqueItems"),
    ("_schemaMaxProperties", "maxProperties"),
    ("_schemaMinProperties", "minProperties"),
    ("_schemaEnum", "enum"),
    ("_schemaConst", "const"),
    ("_schemaExamples", "examples"),
    ("_schemaIf", "if_"),
    ("_schemaThen", "then_"),
    ("_schemaElse", "else_"),
    ("_schemaReadOnly", "readOnly"),
    ("_schemaWriteOnly", "writeOnly"),
    ("_schemaProperties", "properties"),
    ("_schemaPatternProperties", "patternProperties"),
    ("_schemaAdditionalProperties", "additionalProperties"),
    ("_schemaAdditionalItems", "additionalItems"),
    ("_schemaItems", "items"),
    ("_schemaPropertyNames", "propertyNames"),
    ("_schemaContains", "contains"),
    ("_schemaAllOf", "allOf"),
    ("_schemaOneOf", "oneOf"),
    ("_schemaAnyOf", "anyOf"),
    ("_schemaNot", "not"),
    ("_schemaDescription", "description"),
    ("_schemaFormat", "format"),
    ("_schemaDefault", "default_"),
    ("_schemaDiscriminator", "discriminator"),
    ("_schemaExternalDocs", "externalDocs"),
    ("_schemaDeprecated", "deprecated")
  ]
