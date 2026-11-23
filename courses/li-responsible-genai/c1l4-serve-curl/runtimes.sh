#!/usr/bin/env bash
# Lesson 1.1.4: serve the model three ways on localhost and call each with curl.
# apr serves on 8080, llama-server on 8081 (passed explicitly), Ollama is a service on 11434.
# The script starts apr and llama-server itself and stops only those two processes.
# SERVE_WAIT (default 90) is the number of seconds each server gets to answer /health.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
run="${RUN_DIR:-$here/../.run}"
mkdir -p "$run"

apr_url=http://127.0.0.1:8080
llama_url=http://127.0.0.1:8081
ollama_url=http://127.0.0.1:11434
hello='{"model":"default","messages":[{"role":"user","content":"Hello!"}],"max_tokens":50}'

# wait_health URL: true once /health answers, false after SERVE_WAIT seconds.
wait_health() {
  local i
  for i in $(seq 1 "${SERVE_WAIT:-90}"); do
    if curl -s -m 2 "$1/health" >/dev/null 2>&1; then return 0; fi
    sleep 1
  done
  return 1
}

# chat BASE BODY: POST BODY to BASE/v1/chat/completions, print the reply text.
chat() {
  curl -s -X POST "$1/v1/chat/completions" -H "Content-Type: application/json" -d "$2" | jq -r '.choices[0].message.content'
}

apr serve run "$DEMO_GGUF" --port 8080 --no-gpu --offline >"$run/apr-serve.log" 2>&1 &
apr_pid=$!
llama-server -m "$DEMO_GGUF" --host 127.0.0.1 --port 8081 >"$run/llama-server.log" 2>&1 &
llama_pid=$!
trap 'kill "$apr_pid" "$llama_pid" 2>/dev/null' EXIT
wait_health "$apr_url" || echo "apr serve did not answer /health"
wait_health "$llama_url" || echo "llama-server did not answer /health"

show ollama ps
echo '$ curl -s -X POST http://127.0.0.1:8080/v1/chat/completions -H "Content-Type: application/json" -d '"'$hello'"' | jq -r '"'.choices[0].message.content'"
chat "$apr_url" "$hello"
echo '$ same body against http://127.0.0.1:8081'
chat "$llama_url" "$hello"
echo '$ curl -s http://127.0.0.1:11434/api/chat -d <model + messages + stream false> | jq -r .message.content'
curl -s "$ollama_url/api/chat" -d '{"model":"'"$DEMO_OLLAMA_TAG"'","messages":[{"role":"user","content":"Hello!"}],"stream":false}' | jq -r '.message.content'
echo '$ same body as the first, Ollama model name, against http://127.0.0.1:11434'
chat "$ollama_url" '{"model":"'"$DEMO_OLLAMA_TAG"'","messages":[{"role":"user","content":"Hello!"}],"max_tokens":50}'
echo '$ the same call with a broken bracket'
curl -s -i -X POST "$apr_url/v1/chat/completions" -H "Content-Type: application/json" -d '{"model":"default","messages":[{"role":"user","content":"Hello!"]}' | grep -E '^HTTP|^\{'
echo '$ ss -ltn | grep -E "8080|8081|11434"'
ss -ltn | grep -E '8080|8081|11434'
