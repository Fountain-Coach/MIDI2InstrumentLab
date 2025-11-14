# Kickoff Brief

## Objectives
- Deliver a slim, test‑centric A/V Workbench for MIDI 2.0 and AUv3 plugins providing observation, scripting, and reproducible results.
- Become the internal “lab coat” and external reference host.

## Solo Plan
- Keep scope intentionally slim; ship MVP fast.
- Prioritize determinism (headless) and the MIDI 2.0 inspector.
- Add features incrementally with repeatable scripts and artifacts.

## Initial Decisions
- macOS first; Metal UI; Vulkan/SDLKit later.
- MIDI 2.0 path is canonical; AU hosting as a compatibility layer.
- Session schema = JSON (versioned).
- Headless runner is P0 for determinism and CI.
- Secrets never via env; SecretStore‑backed headers only.

## Initial Sprint (solo; ~2 weeks)
- Spike: single‑track playback with internal instrument; MIDI 2.0 inspector MVP (filters + export).
- Session schema v0; save/load minimal state.
- Headless runner v0 that plays a session; export UMP.
- Draft 3 scripts (melody; bend/aftertouch; param ramp); verify artifacts diff locally.
