#!/usr/bin/env bash
# Lesson 1.1.3: the same prompt on all three runtimes, CPU only, apr offline.
# apr and llama.cpp read the same GGUF file; Ollama runs its own copy of the model family.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
show apr run "$DEMO_GGUF" "$DEMO_PROMPT" --chat -n 32 --no-gpu --offline
show apr run "$DEMO_GGUF" "$DEMO_PROMPT" --chat -n 128 --no-gpu --offline
show llama-cli -m "$DEMO_GGUF" -p "$DEMO_PROMPT" -n 128 -st --no-display-prompt
show ollama run "$DEMO_OLLAMA_TAG" "$DEMO_PROMPT" --verbose
