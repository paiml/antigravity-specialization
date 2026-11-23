#!/usr/bin/env bash
set -uo pipefail
. "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
# 1.0 Why agents need tests: a plausible answer that is wrong.
banner "the agent's answer looks right on the obvious input"
d=$(new_work wrong)
stage_into "$d" wrong
"$d/src/slugify.sh" "Hello World"
banner "the tests say otherwise"
if run_tests "$d"; then LESSON_STATUS=FAILED; else echo "tests caught it (exit non-zero), as intended"; fi
finish
