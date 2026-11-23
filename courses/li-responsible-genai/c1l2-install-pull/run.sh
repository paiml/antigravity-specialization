#!/usr/bin/env bash
# Lesson 1.2: check the install, see the cache, resolve a pull without downloading.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
apr --version
echo "--- cached models (first 8 lines)"
apr list | sed -n '1,8p'
echo "--- apr pull --dry-run resolves a short name, no network I/O"
apr pull --dry-run qwen2.5-coder-1.5b
echo "--- inspect the model we will use"
apr inspect "$DEMO_MODEL" | sed -n '1,12p'
