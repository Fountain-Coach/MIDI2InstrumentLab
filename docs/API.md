 # MIDI2InstrumentLab — HTTP API (OpenAPI)
 
 Authoritative spec: `openapi/v1/lab.yml`
 
 Principles
 - Curated and versioned under `openapi/v{major}/`.
 - No generated code in the repo; clients can be generated downstream.
 - Treat the spec as part of the contract; PRs update the spec first, then code.
 
Surface (v1 summary)
- Health: `GET /health` → 200 ok
- Sessions: `POST /sessions`, `GET/PUT/DELETE /sessions/{id}`
- Runs (headless): `POST /runs`, `GET /runs/{id}`, `GET /runs/{id}/artifacts`, `GET /runs/{id}/artifacts/{name}`
- Introspection: `POST /introspect/au` → AU parameters
- Mapping: kept in Tools Factory (canonical). Use its `POST /agent-facts/from-openapi` to generate/seed Facts from curated specs.
 
 Notes
 - Session schema v0 is intentionally minimal but concrete (see `components.schemas.Session`). It will evolve; clients should be tolerant to additional fields.
 - Artifacts may be text or binary; content type is advertised on listing and direct fetch.
 - Security is TBD; local/dev deployments default to no auth. Production deployments should front the service with proper auth.
 
 Curation
 - Keep the spec human‑readable.
 - Use concise, accurate schema descriptions and examples.
 - Avoid over‑specifying fields that are still evolving; allow `additionalProperties: true` where helpful.
 
