# LLM Adapter — Design

Position
- LLM is a power tool to propose transforms and code, not the source of truth. The ground truth is the deterministic runner (headless) and artifacts (UMP/NDJSON/logs).
- Default control surface: chat + tools. Backends implement a single Adapter interface.

Adapter Interface (concept)
- Input: messages [{ role: system|user|assistant, content: string }], optional tool schema, and optional context files.
- Output: assistant content or tool call(s) in a compact JSON format.

Backends
- Ollama (local): HTTP to `http://127.0.0.1:11434/` (no secrets in env; local only).
- OpenAI/Anthropic/etc. (remote): gated; load keys from a secure store (never commit). For this repo, put a local, ignored file under `llm/config/`.

Tool Calls
- The adapter can emit tool invocations from a fixed manifest (see `docs/LLM-Tools.md` and `llm/tools/manifest.json`).
- Tool outputs flow back as context for the next turn. The final step is a patch/build/test plan with artifacts and a summary.

Safety
- No environment secrets. If an adapter needs an API key, store it outside the repo or in a local ignored file under `llm/config/`.
- Code changes must pass headless tests; the adapter never merges without artifacts.

Wireup (repo stubs)
- `scripts/llm-run` — orchestrator (placeholder). Use `--adapter echo` to dry‑run.
- `llm/adapters/` — stubs for `echo`, `ollama`, `openai`.
- `llm/tools/manifest.json` — tool surface declared for the LLM.
- `llm/config/` — local config (ignored); do not commit secrets.

