# LLM Tools — Manifest and Semantics

Purpose
- Small, composable commands the LLM can call to inspect plugins, synthesize mappings, generate/seed facts, build wrappers, and validate via headless artifacts.

Canonical Tools (initial)
- `list-au-parameters` — enumerate AU params, ranges, units.
- `generate-openapi` — synthesize OpenAPI from a param/method map.
- `openapi-to-facts` — produce PE facts; return JSON; optionally seed.
- `secrets-missing` — compare descriptor.authHeaders vs SecretStore; return missing.
- `apply-patch` — apply a patch file to a working tree.
- `build-target` — compile a specific target; return build log.
- `run-headless` — run session; return artifact paths.
- `artifact-diff` — compare two artifact bundles; return pass/fail.

Manifest
- File: `llm/tools/manifest.json`
- Each entry: `{ "name": "tool-id", "command": "bash ...", "input": "json"|"text", "output": "json"|"text" }`

Return Convention
- Tools return JSON on stdout for machine consumption; stderr is logs.
- Use minimal, stable schemas. Example (run-headless): `{ "ok": true, "artifacts": { "ump": "Artifacts/run-.../ump.ndjson", "events": ".../events.ndjson" } }`.

Security
- Never echo secrets. Tools that require headers should read from a secure store only.

This repo ships placeholders only. Wire real commands when integrating with your engine/host.

