#!/usr/bin/env bash
set -uo pipefail
. "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
# 2.4 When the agent edits the test to pass: the tests are green and the work is still rejected.
banner "stage cheat: the test command is green"
d=$(new_work cheat)
stage_into "$d" cheat
run_tests "$d" | tail -n 1
banner "verify against the tests you approved"
if "$ROOT/scripts/verify.sh" "$d" green stub; then LESSON_STATUS=FAILED; else echo "cheat caught"; fi
banner "an honest solution passes the same check"
g=$(new_work honest)
stage_into "$g" green
"$ROOT/scripts/verify.sh" "$g" green stub || LESSON_STATUS=FAILED
finish
