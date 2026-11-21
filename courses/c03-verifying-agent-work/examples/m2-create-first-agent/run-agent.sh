#!/bin/bash
# Live agy step: runs a single non-interactive prompt in plan mode referencing the agent spec.
# Not executed by verify.sh.

set -euo pipefail

command -v agy >/dev/null 2>&1 || {
    echo "error: 'agy' not found. Install the Antigravity CLI first." >&2
    exit 127
}

agy -p 'Read agents/verify-first.md and explain the verification rules it enforces without editing any files.' --mode plan
