# MIDI2InstrumentLab — Architecture Whitepaper

This document details the system architecture, semantic graph model, MIDI 2.0 mapping, GPU scheduling strategy, and determinism guarantees for MIDI2InstrumentLab.

It ties strategy (README) to a concrete, testable implementation that scales from a solo MVP to a robust GPU‑native, MIDI 2.0‑first pipeline with LLM‑assisted tooling.

## 1) System Overview

- Deterministic Core (truth)
  - Headless runner: loads Session (JSON), executes graph, emits artifacts (UMP, NDJSON logs, optional audio captures), and produces a manifest for CI diff.
  - Engine: real‑time scheduler + MIDI 2.0 event fabric + audio bus graph + GPU compute orchestration.
  - SecretStore access: only for headers/credentials used by mapping helpers or external HTTP.

- Developer Surfaces
  - Lab UI (SwiftUI): transport controls, MIDI 2 inspector, clip editor, parameter inspector, logs, and routing.
  - HTTP API (OpenAPI v1): sessions CRUD, headless runs, artifacts, AU introspection, mapping helper.
  - LLM adapter + tools: orchestrates introspection → mapping → facts → build → run‑headless → artifacts diff.

- External Integrations
  - AUv3 host (macOS): focused, single‑instance testing; param mapping → PE.
  - Tools Factory (optional): OpenAPI→Facts generation and secret upsert (gated).

Notes
- The Lab’s API is orchestration; the Host’s “API” is MIDI‑CI PE + Facts. Keep them separate and canonical.

## 2) Semantic Graph Model

Nodes
- InstrumentNode: synth/sampler/etc. Receives MIDI 2 events; outputs audio.
- EffectNode: audio in → audio out; may consume MIDI 2 for modulation.
- ControllerNode: generates MIDI 2 events (e.g., LFO/automation) and PE updates.

Ports (typed)
- EventIn/EventOut: MIDI 2 UMP streams.
- AudioIn/AudioOut: interleaved/stereo/mono buses with declared format.
- PropertyIn/PropertyOut: PE set/get flows, rarely connected directly in UI; observed by runtime.

Edges
- Connect compatible ports (Event→Event, Audio→Audio). Properties are set via PE/descriptor mapping.

Scheduling
1) Compile graph → topological orderings per domain: event pass and audio pass.
2) Event pass: deliver MIDI 2 events for the current audio quantum (e.g., 128/256 samples @ 48 kHz).
3) Audio pass: produce audio buffers by invoking node kernels (CPU or GPU) with sample‑accurate offsets.

Clocks & Transport
- Single logical clock with tempo/meter; quantized loop region; wall‑clock → sample position mapping.
- Ensure event timestamps (UMP) align to sample boundaries within a tolerance.

Determinism
- Headless runner sets seeds, freezes plugin randomness, and records the exact event order/timestamps. Artifacts are compared with a tolerant diff (e.g., UMP timestamps rounded to 1 sample).

## 3) MIDI 2.0 Mapping (UMP, PE, Profiles)

UMP
- Internal transport for all MIDI 2 events. Events are timestamped relative to the audio quantum and delivered before audio rendering.

Property Exchange (PE)
- PE properties define the instrument control surface. Each property maps to either:
  - a local parameter (Instrument/Effect node param), or
  - a mapped HTTP operation (via Facts) for domain services.

Profiles
- Profiles describe standardized behaviors. Where available, a Profile constrains names/ranges and reduces custom wiring.

Facts (canonical)
- facts.functionBlocks[].properties[] carry `id`, `descriptor`, and `mapsTo.openapi` when bridging to HTTP.
- The Host consumes Facts and exposes properties via MIDI‑CI PE; the Lab may call Tools Factory to generate/seed Facts.

## 4) GPU Scheduling (Metal; Vulkan parity)

Constraints
- Audio needs sample‑accurate latency and consistent buffer sizes.
- GPU wants batches, parallel kernels, and minimized synchronization.

Strategy (Metal)
1) Fixed audio quantum N (e.g., 128/256 samples) -> per‑quantum GPU work.
2) Double/triple buffer audio frames and command buffers.
3) Build a command buffer per quantum:
   - Encode per‑note/voice kernels (compute) with shared constant buffers.
   - Encode mixdown/reduction kernels.
   - Signal a `MTLSharedEvent` on completion.
4) CPU audio callback waits on previous quantum’s event (bounded wait only) and submits the next quantum. Never block UI.

Data Flow
- Per‑note lanes: structure‑of‑arrays for pitch, velocity, envelopes, mod.
- Modulation inputs: packed into a constant buffer per quantum (from PE + ControllerNodes).
- Audio out: render to intermediate GPU buffers → copy/map to the device audio buffer just‑in‑time.

Timing
- Use a timeline semaphore/event (Metal SharedEvent; Vulkan timeline semaphore) to coordinate compute completion before device handoff.
- Keep GPU kernels ≤ ~80% of the quantum duration to preserve jitter margin.

Vulkan Parity (SDLKit)
- Replace SharedEvent with timeline semaphore.
- Mirror pipelines & descriptor sets. Keep per‑quantum command buffer recording with pool resets for predictable latency.

## 5) Headless Determinism & Artifacts

Record
- UMP NDJSON: one event per line with timestamp/group/channel/type/note/etc.
- Events NDJSON: structured logs for transport/automation/PE sets/errors.
- Optional audio capture (for offline analysis), including manifest with formats.

Replay
- Reinject UMP with exact timestamps and verify engine processes identical sequences; assert that per‑event hashes match.

Diff
- UMP diff with rounding rules (e.g., 1‑sample timestamp tolerance).
- Log diff by event type/sequence number. Audio diff optional (hash or perceptual metrics).

## 6) LLM Integration (Plan → Run → Validate)

Adapters
- Local: Ollama; Remote: OpenAI/etc. (opt‑in; secrets never in env; user‑side config only).

Tool Surface
- Introspect AU → Propose mapping → Generate OpenAPI → Facts
- Apply patch → Build target → Run headless → Collate artifacts
- Missing secrets audit (from Facts’ descriptor.authHeaders)

Contract
- LLM proposes patches and plans; the runner validates. No auto‑merge without green artifacts.

## 7) HTTP API (Lab Orchestration)

- v1 spec at `openapi/v1/lab.yml`:
  - Sessions CRUD
  - Runs (headless) start/status
  - Artifacts listing/fetch
  - Introspection: AU parameters
  - Mapping helper: OpenAPI + Facts proposal (proxy to generator)

Security
- Local/dev: open. Production: behind auth/reverse proxy. SecretStore for headers.

## 8) Session Schema (v0)

Top‑level
```json
{
  "schema": "avw.session.v0",
  "transport": { "bpm": 120, "meter": "4/4", "loop": true, "loopStart": 0, "loopEnd": 4 },
  "tracks": [ { "id": "t1", "instrument": {"kind": "midi2-internal"}, "clips": [ ... ] } ]
}
```

Evolution
- Keep additionalProperties: true on objects, so clients are tolerant to added fields. Version the `schema` field.

## 9) Extensibility & Interop

- AU bridge: host a single AUv3 for parameter tests; map params → PE for uniform control.
- External services: call via PE→HTTP (Facts). Keep those specs curated elsewhere.
- Vulkan target: parity with Metal via SDLKit backend.

## 10) Roadmap Tie‑In (from Spec)

Phase 1 (MVP)
- Single track; MIDI 2 inspector; clip playback; session save/load; headless runner (UMP/logs).

Phase 2 (Routing + Automation)
- Multi‑track; effect slots; parameter record/playback; per‑note lanes; enhanced inspector/logs.

Phase 3 (Regression + CI)
- Script harness/library; artifact diff; example suites.

## 11) Implementation Notes

- Real‑time safety: never block audio; UI/logging use lock‑free queues.
- GPU memory: ring buffers for constants/audio; avoid heap churn; reuse command buffers.
- Testing: unit tests for event scheduling; integration tests comparing UMP sequences.
- Diagnostics: expose internal counters (missed deadlines, buffer underruns, GPU durations).

