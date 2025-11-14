MIDI2InstrumentLab
===================

Slim A/V Workbench for testing AUv3 and MIDI 2.0 instruments. See `AGENTS.md` for guardrails and scope, and `docs/` for the full context report, spec, and kickoff brief.

Quick Links
- Project Guide: `AGENTS.md`
- Full Context Report: `docs/Full-Context-Report.md`
- Spec + Requirements + Roadmap: `docs/Spec-Requirements-Roadmap.md`
- Kickoff Brief: `docs/Kickoff-Brief.md`
- LLM Adapter: `docs/LLM-Adapter.md`
- LLM Tools: `docs/LLM-Tools.md`

Solo Quickstart
- Read the spec: `docs/Spec-Requirements-Roadmap.md`
- Create your first session stub: `cp sessions/example.avwsession.json my-first.avwsession.json`
- Run headless (placeholder): `bash scripts/headless-run --session my-first.avwsession.json`

LLM Quickstart (local, placeholder)
- Read adapter spec: `docs/LLM-Adapter.md`
- Dry run an adapter call: `bash scripts/llm-run --adapter echo -p "Wrap this AU into a MIDI2 instrument"`
- Inspect tool manifest: `cat llm/tools/manifest.json`
