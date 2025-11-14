 # GUI Creation & Testing (FountainKit Integration)
 
 This guide explains how to integrate MIDI2InstrumentLab with FountainKit’s GUI creation + testing workflow from day one.
 
 Goals
 - Treat the Lab as a first‑class MIDI‑CI instrument in the Host.
 - Drive the Lab via PE/UMP and validate with deterministic artifacts.
 - Keep prompts (Teatro) and Facts in FountainStore only.
 
 ## 1) Facts — Make the Lab an Instrument
 
 - Curated OpenAPI: `openapi/v1/lab.yml`.
 - Generate + seed Facts (tools‑only ops are flagged):
 
 ```bash
 # Start Tools Factory (in FountainKit)
 Scripts/dev/tools-factory-min run &
 
 # Seed Lab facts
 curl -s -X POST http://127.0.0.1:8011/agent-facts/from-openapi \
   -H 'Content-Type: application/json' \
   -d @- <<'JSON'
 { "agentId": "fountain.coach/agent/midi2-instrument-lab/service",
   "seed": true,
   "openapi": $(python3 -c 'import json,sys;print(json.dumps(open("openapi/v1/lab.yml").read()))') }
 JSON
 ```
 
 - Optional: use the facts preview in `facts/lab.facts.json` and apply with FountainKit’s `store-apply-seed` if you need an offline seed.
 
 ## 2) Host — Expose Lab over MIDI‑CI
 
 - Start the Host with the Lab agent id:
 
 ```bash
 HOST_AGENTS=fountain.coach/agent/midi2-instrument-lab/service \
   swift run --package-path Packages/FountainApps midi-instrument-host
 ```
 
 - The Host loads Facts from FountainStore, exposes PE, and routes Lab PE↔HTTP.
 
 ## 3) Teatro Prompts — Creation + MRTS (Store‑only)
 
 - Author two prompts for the Lab UI: Creation (surface + invariants) and MRTS (robot coverage).
 - Seed as FountainStore pages/segments (see FountainKit seeders like `mpe-pad-app-seed` for the pattern). Keep prompts out of files.
 - On boot, the Lab UI should fetch and print both prompts for visibility.
 
 Checklist
 - Corpus: `midi2-instrument-lab` (suggested)
 - Pages: `prompt:midi2-instrument-lab` and `prompt:midi2-instrument-lab-mrts`
 - Segments: `teatro.prompt` (full prompt) + `facts` (structured JSON: instruments, PE, invariants)
 
 ## 4) MIDI Robot Tests — Deterministic Validation
 
 - Use FountainKit’s robot approach to drive the Lab via MIDI‑CI (PE SET/GET) and UMP injection.
 - Minimal loop:
   1) Start Host (Lab agent).
   2) Start a headless run in the Lab (via `POST /runs`).
   3) Collect artifacts (UMP/NDJSON) from `GET /runs/{id}/artifacts`.
   4) Diff artifacts against expected.
 
 - If you prefer pure MIDI‑CI: send UMP (MIDI 2 SysEx7 PE SET) directly to the Host and assert replies.
 
 ## 5) LLM Tools — From Plan to Artifacts (Optional)
 
 - Expose a tool manifest to the LLM that calls:
   - `introspect.au` → `mapping.generate` → seed Facts → `runsStart` → artifacts list + fetch.
 - The LLM proposes; the headless runner validates. No merge without green artifacts.
 
 Notes
 - Facts and prompts live only in FountainStore; seeders write, apps read.
 - Tool‑safe operations in the Lab API are flagged for Facts generation; sessions CRUD remains outside tools by default.
 
