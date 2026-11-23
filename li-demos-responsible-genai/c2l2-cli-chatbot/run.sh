#!/usr/bin/env bash
# Lesson 2.2: a CLI chatbot against your own server. Reads lines from stdin; keeps the history.
# Try:  c2l2-cli-chatbot/run.sh < c2l2-cli-chatbot/input.txt
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
need_server
history='[{"role":"system","content":"You are a concise assistant. Answer in one or two sentences."}]'
while IFS= read -r line; do
  [ -z "$line" ] && continue
  echo "you> $line"
  history=$(printf '%s' "$history" | jq -c --arg u "$line" '. + [{role:"user",content:$u}]')
  if [ -n "${DEMO_STUB:-}" ]; then
    reply=$(cat "$DEMO_STUB")
  else
    body=$(jq -nc --argjson m "$history" '{model:"default",max_tokens:80,temperature:0,messages:$m}')
    reply=$(curl -sS -m 300 "$DEMO_URL/v1/chat/completions" -H 'content-type: application/json' -d "$body" | jq -r '.choices[0].message.content')
  fi
  echo "bot> $reply"
  history=$(printf '%s' "$history" | jq -c --arg a "$reply" '. + [{role:"assistant",content:$a}]')
done
echo "(messages kept in history after the system prompt: $(printf '%s' "$history" | jq 'length - 1'))"
