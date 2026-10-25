# NOTICE

This directory contains files vendored from the
[AsyncAPI specification repository](https://github.com/asyncapi/spec)
at tag `v3.1.0` (commit `b3fac5bb522771428ea57b16129b273cd3ea0180`):

- `asyncapi.md` — from `spec/asyncapi.md`, verbatim.
- `base-doc.json` — from `scripts/validation/base-doc-combined.json`, with the
  `"asyncapi"` version field changed from `"3.0.0"` to `"3.1.0"` (the upstream
  file had not been bumped when the tag was cut; the examples all declare 3.1.0).
- `examples/` — from `examples/`, verbatim (24 documents: 19 top-level YAML
  files plus 5 `social-media/*/asyncapi.yaml`).

The AsyncAPI specification is copyright the AsyncAPI Initiative and licensed
under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).
