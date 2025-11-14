MIDI2InstrumentLab
===================

Deep technical + strategic analysis of “Audio Land” over the next decade, with specific implications for this project. This is not generic commentary — it is tailored to our position: Directly on Metal (GPU), MIDI 2.0‑native, Vulkan portability via SDLKit, and LLM‑aware development.

1) You’re In The Right Place: Directly On Metal
- Most audio stacks are many layers above hardware (DAW → plugin SDKs → AU/VST → OS abstractions → CoreAudio/MIDI → OS → GPU/CPU).
- We sit two layers above silicon. That unlocks low‑latency graphics+compute pipelines and precise timing that classic audio APIs struggle to deliver.

2) MIDI 2.0 Changes The Event Model
- From MIDI 1.x (channel‑centric, integer, one‑way) to MIDI 2.0 (per‑note expression, profiles, property exchange, high‑resolution, bidirectional negotiation).
- Legacy hosts will shoehorn MIDI 2 into old abstractions; true support may be years out.
- We already run a modern event fabric — lossless UMP, per‑note lanes, PE, profile‑driven behavior — without old API constraints.

3) GPU‑Native Audio Synthesis Is Coming — We’re Ahead
- LLMs, differentiable audio, neural synths (DDSP, RAVE, MusicGen) are GPU‑first.
- DAWs still assume CPU‑only audio; graphics on GPU; no shared clock.
- Our Metal compute path enables oscillator banks, wavetables, convolution, granular, physical modeling, and differentiable DSP as first‑class GPU workloads.

4) LLM Reality: The Workflow Becomes Semantic
- New loop: “User prompt” → LLM agent → Semantic modulation graph → Engine executes.
- MIDI 2.0 PE is the structured bridge between semantic intent and parameter application.
- Our instruments (Metal) become targets in that semantic graph; DAWs/plugins aren’t ready — we are.

5) Apple’s Problem: CoreMIDI Is Old + Not Swift‑Native
- CoreMIDI (C‑based callbacks) is a poor fit for Swift 6 concurrency and GPU/compute flows.
- Expect slow modernization of AUv3/CoreMIDI for PE/Profiles.
- Consequence: engines that matter will implement their own MIDI 2 routing/event fabrics.

6) Expectation #1 — Replace CoreMIDI For Serious Work
- Rich MIDI 2 semantics + concurrency demand host‑native fabrics. We already have them.

7) Expectation #2 — Audio Moves Toward Graph Semantics
- Next‑gen “DAW” looks like a semantic graph engine (nodes: instruments/effects/controllers; edges: event/audio buses; graph state: AI‑generated). Our SDLKit+host+MIDI2 layer already is a graph runtime.

8) Expectation #3 — Synthesis/Modulation Move Onto The GPU
- AUv3 isn’t GPU‑first; plugin IPC and callback models resist GPU scheduling.
- Independent engines on Metal/Vulkan will lead. We’re positioned to be among them.

9) Expectation #4 — MIDI 2 Profiles Become The New “Plugin API”
- Standardized instrument behaviors + PE metadata = structured control surface.
- LLMs thrive on structured standards; hosts can reason and map consistently.
- Long term: Instruments define Profiles; hosts map; AU/VST become compatibility shells.

10) Expectation #5 — Audio Toolchains Become Cross‑Platform AI Pipelines
- LLMs need symbolic control (MIDI2), GPU compute (Metal/Vulkan), node topologies, and real‑time simulation. CoreAudio/MIDI become compatibility layers; engines like ours become primary pipelines.

11) Plainly: Our Advantage
- Metal + custom instrument host + MIDI 2.0 + Vulkan via SDLKit. The market is moving toward GPU‑native, LLM‑assisted, MIDI2 semantic control graphs. We can lead now, not in 5–10 years.

12) What To Do Now
- Make MIDI 2 Profiles + PE our semantic API.
- Build and use a slim A/V Workbench — a lab coat — not a consumer DAW.
- Keep pushing GPU compute DSP; don’t wait for legacy stacks.
- Position the engine as a semantic, GPU‑first, MIDI2‑native pipeline with LLM orchestration.

Project Direction: MIDI2InstrumentLab
- Purpose: A slim, deterministic A/V Workbench for AUv3 + MIDI 2.0. It is our debugger, demonstrator, and orchestration harness.
- Roles:
  - Deterministic runner (headless) + artifacts (UMP/NDJSON/logs) as the single source of truth.
  - Developer utilities: AU parameter introspection; mapping helper (OpenAPI→Facts); sessions/runs/artifact APIs.
  - LLM adapter: a power tool that proposes transforms, scaffolds wrappers, composes tests — never the source of truth.

Guardrails (Forever “Slim”)
- In: transport, minimal track model, MIDI 2 inspector, clip editor (piano roll + per‑note lanes), AUv3 hosting, parameter inspector/automation, session save/load, headless runner.
- Out: consumer DAW features (mixers, editing/comping, mastering, plugin marketplaces). Determinism, speed, and clarity over breadth.

Security
- No environment secrets. If endpoints require credentials, store header maps in a SecretStore document (corpus `secrets`). The Lab may expose a gated helper to upsert headers — it never echoes values.

OpenAPI (Canonical, Curated)
- API is versioned and curated in‑repo; no generated code is committed.
- v1 covers: sessions CRUD, headless runs, artifacts, AU introspection, mapping helper.
  - Spec: `openapi/v1/lab.yml` (see `docs/API.md`).

Solo Quickstart
- Read the spec: `docs/Spec-Requirements-Roadmap.md`
- Create your first session stub: `cp sessions/example.avwsession.json my-first.avwsession.json`
- Run headless (placeholder): `bash scripts/headless-run --session my-first.avwsession.json`

LLM Quickstart (local, placeholder)
- Read adapter spec: `docs/LLM-Adapter.md`
- Dry run an adapter call: `bash scripts/llm-run --adapter echo -p "Wrap this AU into a MIDI2 instrument"`
- Inspect tool manifest: `cat llm/tools/manifest.json`

Quick Links
- Project Guide: `AGENTS.md`
- Full Context Report: `docs/Full-Context-Report.md`
- Spec + Requirements + Roadmap: `docs/Spec-Requirements-Roadmap.md`
- Kickoff Brief: `docs/Kickoff-Brief.md`
- LLM Adapter: `docs/LLM-Adapter.md`
- LLM Tools: `docs/LLM-Tools.md`
- HTTP API (OpenAPI): `openapi/v1/lab.yml` (see `docs/API.md`)
- Architecture Whitepaper: `Design/ARCHITECTURE.md`
