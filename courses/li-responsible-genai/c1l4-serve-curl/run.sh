#!/usr/bin/env bash
# Lesson 1.4: serve on localhost, then call it with curl. Needs scripts/serve.sh running.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
need_server
echo "--- GET /health"
curl -sS "$DEMO_URL/health" | jq 'del(.binary_sha256, .uptime_sec)'
echo "--- GET /v1/models"
curl -sS "$DEMO_URL/v1/models" | jq -c '.data[0] | {id, owned_by}'
echo "--- POST /v1/chat/completions"
curl -sS "$DEMO_URL/v1/chat/completions" -H 'content-type: application/json' \
  -d '{"model":"default","messages":[{"role":"user","content":"Say hi in 3 words"}],"max_tokens":16}' \
  | jq -c '{reply: .choices[0].message.content, usage}'
