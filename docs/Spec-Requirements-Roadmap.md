# Spec, Requirements, and Roadmap

## Codex Spec

- Purpose: Build a slim, developer-focused A/V Workbench for AUv3 + MIDI 2.0 instruments; deterministic + scriptable.
- Scope: macOS host + headless; AUv3, MIDI2 inspector, clip editor, transport, routing, session save/load.
- Non-Goals: No consumer DAW features; keep test-centric.
- Audience: AU devs, QA, internal teams.
- Interfaces: Headless CLI (`avw headless --session <file> --script <file>`); session JSON; NDJSON logs; UMP capture.
- Security: No env secrets; SecretStore-backed header maps only.

## Functional Requirements

- Transport: play/stop/loop; tempo + time signature.
- Tracks: MIDI tracks → instruments; effect slots; audio return to master.
- MIDI 2 inspector: UMP live view; filters; export; scrollback.
- Clip editor: piano roll; per-note expression lanes; controller lanes.
- Parameter inspector + automation: get/set/record/playback.
- Session: versioned JSON schema; save/load; portable assets.
- Headless: deterministic playback; dump UMP/logs; artifact diff.

## Non-Functional Requirements

- Low-latency; UI off real-time threads; deterministic headless mode.
- Extensible panels; stable session schema; minimal cold start.

## Risks and Mitigations

- Scope creep → strict guardrails; ship MVP fast.
- AU stability → isolate and document recovery.
- Timing determinism → headless defines truth; record/replay.

## Roadmap

### Phase 1 — MVP (4–6 weeks)
- Single track transport; MIDI 2.0 inspector; basic clip playback.
- Session save/load; headless runner; UMP export.

### Phase 2 — Routing + Automation (4–6 weeks)
- Multi-track; effect slots; parameter record/playback; per-note lanes.
- Enhanced logging + inspector.

### Phase 3 — Regression + CI (3–4 weeks)
- Script harness/library; artifact diff; example suites.

### Phase 4 — DX Polish (ongoing)
- AU preset/state tests; session templates; perf dashboards.

