#!/usr/bin/env bash
set -uo pipefail
. "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
# 4.5 The reusable template: copy it, and it starts red on purpose.
d=$(new_work template)
stage_into "$d" stub
ls -a "$d"
banner "a new project from the template starts red"
if run_tests "$d" | tail -n 2; then LESSON_STATUS=FAILED; else echo "red, as intended: now write the first real test"; fi
finish
