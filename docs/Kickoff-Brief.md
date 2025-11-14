# Kickoff Brief

## Objectives
- Deliver a slim, test‑centric A/V Workbench for MIDI 2.0 and AUv3 plugins providing observation, scripting, and reproducible results.
- Become the internal “lab coat” and external reference host.

## Team/Roles
- Tech Lead: architecture, guardrails, determinism
- Engine Lead: scheduling, UMP recorder, audio graph
- UI/UX: SwiftUI panes (inspector, clips, logs, routing)
- AU Integration: AUv3 load/state/params
- QA/Automation: scripted scenarios + CI
- Docs/DevRel: quickstarts, examples, regression guide

## Initial Decisions
- macOS first; Metal UI; Vulkan/SDLKit later.
- MIDI 2.0 path is canonical; AU hosting as a compatibility layer.
- Session schema = JSON (versioned).
- Headless runner is P0 for determinism and CI.
- Secrets never via env; SecretStore‑backed headers only.

## Sprint 0 (2 weeks)
- Spike: single-track playback with internal instrument; UMP inspector pane MVP (filters + export).
- Session schema v0; save/load minimal state.
- Headless runner v0 playing a session; exports UMP.
- Draft 3 scripted scenarios (melody; bend/aftertouch; param ramp).
- Review milestone plan; confirm guardrails.

