#!/usr/bin/env bash
# Shared helpers for the terminal demos. Source this file; it sets no shell options.
DEMO_ROOT="${DEMO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
DEMO_URL="${DEMO_URL:-http://127.0.0.1:18931}"
DEMO_MODEL="${DEMO_MODEL:-$HOME/.cache/pacha/models/qwen-1.5b-q4k.apr}"
export DEMO_ROOT DEMO_URL DEMO_MODEL

# chat_raw SYSTEM USER MAXTOKENS -> full JSON reply from the local server.
# DEMO_STUB (a file) replaces the server in tests: its content is returned as the reply text.
chat_raw() {
  local sys="$1" user="$2" max="${3:-96}" body
  if [ -n "${DEMO_STUB:-}" ]; then
    jq -n --rawfile t "$DEMO_STUB" '{choices:[{message:{content:$t}}],usage:{completion_tokens:0}}'
    return 0
  fi
  body=$(jq -n --arg s "$sys" --arg u "$user" --argjson m "$max" \
    '{model:"default",max_tokens:$m,temperature:0,messages:(([{role:"system",content:$s}]|map(select(.content!=""))) + [{role:"user",content:$u}])}')
  curl -sS -m 300 "$DEMO_URL/v1/chat/completions" -H 'content-type: application/json' -d "$body"
}

# ask SYSTEM USER [MAXTOKENS] -> reply text only.
ask() {
  chat_raw "$1" "$2" "${3:-96}" | jq -r '.choices[0].message.content // empty'
}

# need_server: stop with a clear message when no server answers (live demos only).
need_server() {
  if [ -n "${DEMO_STUB:-}" ]; then return 0; fi
  if ! curl -sS -m 5 "$DEMO_URL/health" >/dev/null 2>&1; then
    echo "no server at $DEMO_URL: run scripts/serve.sh first" >&2
    return 1
  fi
}

# redact: stdin -> stdout with key-shaped, bearer and email secrets masked.
redact() {
  sed -E \
    -e 's/(sk|pk)-[A-Za-z0-9]{12,}/[REDACTED-KEY]/g' \
    -e 's/AKIA[0-9A-Z]{16}/[REDACTED-AWS]/g' \
    -e 's/[0-9]{3}-[0-9]{2}-[0-9]{4}/[REDACTED-SSN]/g' \
    -e 's/Bearer [A-Za-z0-9._-]{12,}/[REDACTED-TOKEN]/g' \
    -e 's/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/[REDACTED-EMAIL]/g'
}

# sensitivity TEXT -> prints "high" or "low" (used by the router and the guardrails).
sensitivity() {
  if printf '%s' "$1" | grep -Eiq '(ssn|social security|password|patient|diagnos|salary|[0-9]{3}-[0-9]{2}-[0-9]{4}|(sk|pk)-[A-Za-z0-9]{12,}|confidential)'; then
    echo high
  else
    echo low
  fi
}

# audit_append LOGFILE EVENT: hash-chained JSON line (each line holds the sha256 of the previous line).
audit_append() {
  local log="$1" event="$2" prev
  if [ -s "$log" ]; then prev=$(tail -n 1 "$log" | sha256sum | cut -d' ' -f1); else prev=GENESIS; fi
  jq -nc --arg e "$event" --arg p "$prev" '{event:$e,prev:$p}' >>"$log"
}

# audit_verify LOGFILE: prints OK or the first broken line number; exit 1 when broken.
audit_verify() {
  local log="$1" n=0 prev=GENESIS line want
  while IFS= read -r line; do
    n=$((n + 1))
    want=$(printf '%s' "$line" | jq -r '.prev')
    if [ "$want" != "$prev" ]; then echo "BROKEN at line $n"; return 1; fi
    prev=$(printf '%s\n' "$line" | sha256sum | cut -d' ' -f1)
  done <"$log"
  echo "OK $n lines"
}

# Three-runtime lessons (1.1.2 to 1.1.5). One small model family on all three runtimes:
# apr and llama.cpp read the same GGUF file here; Ollama holds its own copy of the family.
DEMO_GGUF="${DEMO_GGUF:-$HOME/.cache/pacha/models/8de7eb9c0c789ccb.gguf}"
DEMO_OLLAMA_TAG="${DEMO_OLLAMA_TAG:-qwen2.5-coder:0.5b}"
DEMO_PROMPT="${DEMO_PROMPT:-What is a hash function? Answer in two sentences.}"
export DEMO_GGUF DEMO_OLLAMA_TAG DEMO_PROMPT

# show CMD...: print the command with a "$ " prompt, run it, strip terminal control codes from the output.
# The exit code of the command is not propagated: a lesson shows failures, it does not stop on them.
show() {
  printf '$ %s\n' "$*"
  "$@" 2>&1 | sed -E 's/\x1b\[[0-9;?]*[A-Za-z]//g; s/\r//g' || true
  return 0
}
