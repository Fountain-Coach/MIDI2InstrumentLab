#!/usr/bin/env bash
set -euo pipefail

# Ollama adapter (placeholder). Requires local ollama running.
# Usage: ollama.sh --model llama3 --prompt "..."

MODEL="llama3"
PROMPT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --model) MODEL="${2:-$MODEL}"; shift 2;;
    -p|--prompt) PROMPT="${2:-}"; shift 2;;
    --prompt-file) PROMPT="$(cat "${2:-}")"; shift 2;;
    *) shift;;
  esac
done

if [[ -z "$PROMPT" ]]; then echo "error: --prompt required" >&2; exit 2; fi

curl -s http://127.0.0.1:11434/api/generate \
  -H 'Content-Type: application/json' \
  -d "{\"model\":\"$MODEL\",\"prompt\":$(python3 -c 'import json,sys;print(json.dumps(sys.argv[1]))' "$PROMPT"),\"stream\":false}" \
  | python3 -c 'import json,sys;print(json.dumps({"assistant":json.load(sys.stdin).get("response","" )}))'

