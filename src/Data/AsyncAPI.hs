-- | Umbrella module for the AsyncAPI 3.1.0 data-model library.
--
-- Re-exports the model ('Data.AsyncAPI.Internal', 'Data.AsyncAPI.Internal.Schema',
-- 'Data.AsyncAPI.Internal.Types'), the ordered-encoding helpers, the validator,
-- and both optic interfaces.
--
-- == Optics
--
-- Both optic libraries are re-exported under their module names; import one
-- of 'Data.AsyncAPI.Lens' or 'Data.AsyncAPI.Optics' qualified to use the
-- prisms (they share constructor names with different types). The lens
-- field @id@ on 'AsyncAPI' shadows 'Prelude.id' when imported unqualified.
--
-- == Roundtrip contract
--
-- Aeson's key-map loses source order on decode, so every map-typed field and
-- every @x-@ extension map is re-inserted /sorted by key/ on decode; encoding
-- always emits fixed fields in the specification's table order, omits absent
-- optional fields, and appends @x-@ extensions last. The contract is:
-- structural 'Eq' equality plus byte-stable 'Data.Aeson.encode' output.
--
-- See the specification:
-- <https://www.asyncapi.com/docs/reference/specification/v3.1.0 AsyncAPI 3.1.0>.
module Data.AsyncAPI
  ( -- * Model
    module Data.AsyncAPI.Internal,
    module Data.AsyncAPI.Internal.Schema,
    module Data.AsyncAPI.Internal.Types,

    -- * Encoding helpers
    module Data.AsyncAPI.Internal.Encoding,

    -- * Validation
    module Data.AsyncAPI.Validation,

    -- * Optics
    module Data.AsyncAPI.Lens,
    module Data.AsyncAPI.Optics,
  )
where

import Data.AsyncAPI.Internal
import Data.AsyncAPI.Internal.Encoding
import Data.AsyncAPI.Internal.Schema
import Data.AsyncAPI.Internal.Types
import Data.AsyncAPI.Lens qualified
import Data.AsyncAPI.Optics qualified
import Data.AsyncAPI.Validation
