#!/bin/bash
# Live Antigravity analysis step (marked live=true in example.toml; NOT run by verify.sh).
# Uses --mode plan so the agent inspects target-repo/ read-only without editing files.

set -euo pipefail

command -v agy >/dev/null 2>&1 || {
    echo "error: 'agy' not found. Install the Antigravity CLI first." >&2
    exit 127
}

HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE/target-repo"

agy -p 'Audit this repository for verification gaps (CI exit-code swallowing, unpinned actions, missing strict mode, and vacuous tests). Cite exact file:line locations for every finding. Do not edit any files.' --mode plan
