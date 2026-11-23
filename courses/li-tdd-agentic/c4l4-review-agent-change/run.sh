#!/usr/bin/env bash
set -uo pipefail
. "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
# 4.4 Reviewing an agent change. MIXED: the pull request page is a UI; the first checks are mechanical.
a=$(new_work old); b=$(new_work good); c=$(new_work bad)
stage_into "$a" n-red
stage_into "$b" n-green
banner "change 1: an implementation task; tests untouched, source changed"
"$ROOT/scripts/review-diff.sh" "$a" "$b" impl || LESSON_STATUS=FAILED
stage_into "$a" stub
stage_into "$c" cheat
banner "change 2: an implementation task that edited the tests: must be flagged"
if "$ROOT/scripts/review-diff.sh" "$a" "$c" impl; then LESSON_STATUS=FAILED; else echo "flagged, as intended"; fi
finish
