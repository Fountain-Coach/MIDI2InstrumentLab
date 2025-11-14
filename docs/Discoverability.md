# Discoverability — Host Instrument Facts

Goal
- Make the Lab discoverable as a MIDI‑CI instrument by providing PE Facts that map properties to the Lab’s HTTP API operations.

Facts (preview)
- A preview Facts document is committed under `facts/lab.facts.json`.
- Canonical generation should still be done via your generator (e.g., Tools Factory `openapi-to-facts`) from the curated OpenAPI (`openapi/v1/lab.yml`).

Agent Id
- Suggested: `fountain.coach/agent/midi2-instrument-lab/service`
- Hosts can seed Facts into FountainStore under `facts:agent:fountain.coach|agent|midi2-instrument-lab|service` (corpus `agents` by default).

Seeding via Tools Factory (recommended)
```bash
# Post OpenAPI and seed Facts (tools-only ops are flagged in the spec)
curl -s -X POST "${TOOLS_FACTORY_URL:-http://127.0.0.1:8011}/agent-facts/from-openapi" \
  -H 'Content-Type: application/json' \
  -d @- <<'JSON'
{ "agentId": "fountain.coach/agent/midi2-instrument-lab/service", "seed": true,
  "openapi": $(python3 -c 'import json,sys;print(json.dumps(open("openapi/v1/lab.yml").read()))') }
JSON
```

Direct seeding (fallback)
- Use the Facts preview: write `facts/lab.facts.json` into FountainStore under `agent-facts` collection, id `facts:agent:fountain.coach|agent|midi2-instrument-lab|service`.

Host Behavior
- The host loads Facts, exposes properties via MIDI‑CI PE, and routes PE SET/GET to HTTP (per spec). Only tool‑safe operations were included for safety.

