#!/bin/bash
# Safe first step with the Antigravity CLI: single-turn read-only exploration.
# Live agy step -- requires `agy` on PATH; not executed by verify.sh.

set -euo pipefail

command -v agy >/dev/null 2>&1 || {
    echo "error: 'agy' not found. Install the Antigravity CLI first." >&2
    exit 127
}

agy -p 'Inspect the current directory, list its files, and summarize any verification contracts without editing any files.' --mode plan
