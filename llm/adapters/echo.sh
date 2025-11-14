#!/usr/bin/env bash
set -euo pipefail

# Echo adapter: prints a canned plan based on the prompt.
PROMPT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--prompt) PROMPT="${2:-}"; shift 2;;
    --prompt-file) PROMPT="$(cat "${2:-}")"; shift 2;;
    *) shift;;
  esac
done

printf '{"plan":["introspect","generate-openapi","facts","build","run-headless"],"prompt":%s}\n' "$(printf '%s' "$PROMPT" | python3 -c 'import json,sys;print(json.dumps(sys.stdin.read()))')"

