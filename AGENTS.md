 # MIDI2InstrumentLab — Agent Guide (Project Home)
 
 What
 - MIDI2InstrumentLab is a slim, developer‑focused Audio/Visual Workbench for testing Audio Units (AUv3) and MIDI 2.0 instruments. It provides deterministic playback, a MIDI 2.0 inspector, a lightweight clip editor, and headless automation for CI.
 
 Why
 - AU Lab is gone; DAWs are not great debugging tools. A small, purpose‑built host helps developers and QA reproduce issues, observe MIDI 2.0 (UMP, PE), and run regression suites without DAW overhead.
 
 Scope (guardrails)
 - In: transport (play/stop/loop), minimal track model, AUv3 hosting, MIDI 2.0 inspector, clip editor (piano roll + per‑note expression), parameter inspector/automation, session save/load, headless runner.
 - Out: consumer DAW features (mixers, audio editing, comping, mastering chains, plugin marketplace). Keep it fast, test‑centric, deterministic.
 
 How (high‑level)
 - Engine: reuse existing real‑time engine and instrument host (Metal on macOS; Vulkan via SDLKit later).
 - MIDI 2.0: use UMP stack and Property Exchange for observation; record/replay UMP for determinism.
 - AU Hosting: AUv3 (macOS) for targeted plugin validation.
 - Persistence: versioned JSON session schema; headless runner for CI.
 
 Security (secrets)
 - No environment injection for credentials. If external endpoints/tools need auth, store header maps in FountainStore SecretStore only (corpus `secrets`, collection `secrets`, ids `secret:agent:<agent-id>`). Tools may offer a gated endpoint to upsert headers; never echo secret values.
 
 Structure
 - `README.md` — quick intro and links.
 - `docs/Full-Context-Report.md` — verbatim handoff context (problem, rationale, path).
 - `docs/Spec-Requirements-Roadmap.md` — codex spec, requirements, roadmap.
 - `docs/Kickoff-Brief.md` — sprint‑ready kickoff brief.
 - `.github/workflows/ci.yml` — minimal CI sanity (swift toolchain presence).
 - `.gitignore` — Swift/Xcode/macOS ignores.
 
Next steps (solo milestones)
1) MVP: single track transport + MIDI 2.0 inspector; basic clip playback; session save/load; headless run with UMP export.
2) Routing + automation: multi‑track, effect slots, parameter record/playback; per‑note lanes.
3) Regression + CI: headless scenario runner, artifact diff (UMP/NDJSON), example test suites.
 
