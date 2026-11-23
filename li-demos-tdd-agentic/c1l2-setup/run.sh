#!/usr/bin/env bash
set -uo pipefail
. "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
# 1.2 Setup: pinned agy, what it offers, and the repo state to open in Antigravity.
# MIXED: opening the folder in the Antigravity desktop app is a UI step (see DEMO-STATUS.md).
banner "pinned agy version"
agy_pin || LESSON_STATUS=FAILED
banner "agy models (first 3)"
"$AGY_BIN" models 2>&1 | head -n 4
banner "agy agents"
"$AGY_BIN" agents 2>&1 | head -n 5
banner "the project the agent will work on"
ls "$ROOT/project" "$ROOT/project/spec"
echo "UI STEP (not run here): open $ROOT/project in Antigravity"
finish
