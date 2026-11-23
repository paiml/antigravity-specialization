#!/usr/bin/env bash
# Lesson 1.1.2: check all three runtimes and look at what each one holds for the course model family.
# Offline: `apr pull --dry-run` resolves the name and does no network I/O. No model is downloaded.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
show apr --version
show llama-cli --version
show ollama --version
show apr pull --dry-run hf://Qwen/Qwen2.5-Coder-0.5B-Instruct
show ollama ps
show apr list
show llama-cli --cache-list
show ollama show "$DEMO_OLLAMA_TAG"
