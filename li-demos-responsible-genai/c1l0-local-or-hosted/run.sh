#!/usr/bin/env bash
# Lesson 1.1.0 (intro): the three runtimes by version, then one prompt answered offline on this machine.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
show apr --version
show llama-cli --version
show ollama --version
show apr run "$DEMO_GGUF" "What is 2+2?" --chat -n 24 --no-gpu --offline
