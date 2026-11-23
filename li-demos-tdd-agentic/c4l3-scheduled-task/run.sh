#!/usr/bin/env bash
set -uo pipefail
. "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
# 4.3 A scheduled agent task that keeps tests green. The schedule is a plain cron line (printed, never installed).
banner "if the tests are already green the task does nothing"
g=$(new_work already-green)
stage_into "$g" n-green
if run_tests "$g" >/dev/null; then echo "green: nothing to do"; else LESSON_STATUS=FAILED; fi
banner "when they are red the task asks the agent to fix src, and verifies"
agent_lesson n-red keep-green.md green n-green n-red
echo
echo "cron line (not installed): 17 * * * * cd /path/to/project && make test || agy --print --mode accept-edits \"\$(cat prompts/keep-green.md)\""
finish
