# asyncapi3

Haskell data-model library for [AsyncAPI 3.1.0](https://www.asyncapi.com/docs/reference/specification/v3.1.0)
documents, in the spirit of Hackage's `openapi3`: a typed AST mirroring the
specification objects, JSON encoding/decoding via `aeson`, ordered-map
preservation, lens and optics interfaces, and a structural validator.

## Modules

| Module | Contents |
|---|---|
| `Data.AsyncAPI` | Umbrella re-export of the public surface |
| `Data.AsyncAPI.Internal` | Object model: AsyncAPI root, Info, Servers, Channels, Messages, Operations, Security, Bindings, Components |
| `Data.AsyncAPI.Internal.Schema` | Schema Object AST (JSON Schema draft-07 superset, boolean schemas included) |
| `Data.AsyncAPI.Internal.Referenced` | `Reference` / `Referenced`, Tag, External Documentation |
| `Data.AsyncAPI.Internal.Encoding` | Ordered-omitting encoder helpers, `x-` extension handling |
| `Data.AsyncAPI.Internal.Types` | Shared text newtypes (`Title`, `Name`, `Version`, `Id`, `Summary`, `Description`, `Url`, `ContentType`, `RuntimeExpression`) |
| `Data.AsyncAPI.Lens` | `lens` field lenses (`makeFields`) + prisms |
| `Data.AsyncAPI.Optics` | `optics` field labels (`#title`) + prisms |
| `Data.AsyncAPI.Validation` | Structural validator |

## Usage

```haskell
{-# LANGUAGE OverloadedStrings, RecordWildCards #-}
import Data.Aeson (encode)
import Data.ByteString.Lazy.Char8 (putStrLn)
import Data.HashMap.Strict.InsOrd qualified as InsOrd
import Data.AsyncAPI

doc :: AsyncAPI
doc =
  (emptyAsyncAPI "3.1.0" info)
    { _asyncAPIDefaultContentType = Just "application/json" }
  where
    info = emptyInfo "Demo" "1.0.0"

main = putStrLn (encode doc)
-- {"asyncapi":"3.1.0","info":{"title":"Demo","version":"1.0.0"},"defaultContentType":"application/json"}
```

Encoding contract: fixed fields are emitted in the specification's table
order, absent optional fields are omitted, and `x-` extensions follow the
fixed fields. Decoding re-inserts map-typed fields and extensions sorted by
key (aeson's key-map loses source order), so the roundtrip contract is
structural `Eq` equality plus byte-stable `encode` output.

Every record type in the model has an `empty<Type>` constructor taking
exactly its REQUIRED fields (in declaration order) and leaving everything
else unset; combine it with record update to fill optional fields. Repeated
text fields are newtypes (`Title`, `Name`, `Version`, `Id`, `Summary`,
`Description`, `Url`, `ContentType`, `RuntimeExpression`) that derive
`IsString`, so string literals work unchanged, expose `getTitle`-style
accessors, and encode to JSON identically to bare `Text`.

The validator checks the version string, resolution of internal `#/`
references, and that every `schemaFormat` is in the spec's MUST-support
table.

## Tests

The test suite enforces conformance against the vendored specification
(`reference/asyncapi.md`, tag `v3.1.0`, commit `b3fac5bb`; see
`reference/NOTICE.md`):

- one golden test per example embedded in the spec (89
  `asyncapi-example-tester` blocks + the 4 Identifier examples), each decoded
  into the model type at its `json_pointer` and byte-compared, plus a
  `decode (encode v) == v` roundtrip check;
- golden + validation tests over all 24 real-world example documents;
- a repository-level conformance test (every Haddock spec anchor exists in
  the vendored spec; every yaml/json block in the spec is covered or
  explicitly skipped with a reason);
- validator red-case-per-rule tests.

## Adding a field to a spec object

Each object is transcribed four times that must stay in sync: the record, its
ordered `ToJSON` field list, its `FromJSON` field list, and (for the four
keyword-key records) the explicit lens/label lists in `Data.AsyncAPI.Lens` /
`Data.AsyncAPI.Internal.FieldNames`. Update all of them, then rerun the
golden tests.

## Development

```sh
cabal build all
cabal test all
nix develop          # GHC 9.10.3 + cabal + HLS
```

Goldens live under `test/golden/`; refresh them with the
`hspec-golden` update flow after an intentional encoding change (delete the
stale golden and rerun, or use `hgold`).

License: ISC. The vendored specification is Apache-2.0 (AsyncAPI Initiative).
