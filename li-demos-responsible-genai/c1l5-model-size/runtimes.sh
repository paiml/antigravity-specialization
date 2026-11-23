#!/usr/bin/env bash
# Lesson 1.1.5: compare the three runtimes on one prompt: speed lines, file formats, licence.
# Speed is read from each tool's own report; the figures belong to the machine they ran on.
# `apr serve plan` is not in this script: apr 0.74.0 refuses it for a GGUF file (needs its contracts directory).
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
show apr run "$DEMO_GGUF" "$DEMO_PROMPT" --chat -n 128 --no-gpu --offline --benchmark
show llama-cli -m "$DEMO_GGUF" -p "$DEMO_PROMPT" -n 128 -st --no-display-prompt
show ollama run "$DEMO_OLLAMA_TAG" "$DEMO_PROMPT" --verbose
show apr list
show llama-cli --cache-list
show ollama show "$DEMO_OLLAMA_TAG"
echo '$ ollama show '"$DEMO_OLLAMA_TAG"' --license | head -3'
ollama show "$DEMO_OLLAMA_TAG" --license | head -3
