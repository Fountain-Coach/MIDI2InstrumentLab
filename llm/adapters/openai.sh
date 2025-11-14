#!/usr/bin/env bash
set -euo pipefail

# OpenAI adapter (placeholder). Requires a local config file with an API key.
# Config: llm/config/openai.json { "api_key": "sk-...", "base_url": "https://api.openai.com/v1", "model": "gpt-4o-mini" }

CONF="llm/config/openai.json"
[[ -f "$CONF" ]] || { echo "error: missing $CONF (ignored by git)" >&2; exit 2; }

API_KEY=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["api_key"])' "$CONF")
BASE_URL=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("base_url","https://api.openai.com/v1"))' "$CONF")
MODEL=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("model","gpt-4o-mini"))' "$CONF")

PROMPT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--prompt) PROMPT="${2:-}"; shift 2;;
    --prompt-file) PROMPT="$(cat "${2:-}")"; shift 2;;
    *) shift;;
  esac
done

if [[ -z "$PROMPT" ]]; then echo "error: --prompt required" >&2; exit 2; fi

curl -s "$BASE_URL/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d "{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":$(python3 -c 'import json,sys;print(json.dumps(sys.argv[1]))' "$PROMPT")}]}" \
  | python3 -c 'import json,sys;resp=json.load(sys.stdin);print(json.dumps({"assistant":resp.get("choices",[{}])[0].get("message",{}).get("content","") }))'

