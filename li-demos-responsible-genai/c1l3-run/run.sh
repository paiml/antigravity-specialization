#!/usr/bin/env bash
# Lesson 1.3: run a model once in the terminal, offline, CPU only.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
apr run "$DEMO_MODEL" "What is 2+2?" --chat -n 24 --no-gpu --offline
