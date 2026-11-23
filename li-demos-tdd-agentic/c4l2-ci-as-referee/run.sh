#!/usr/bin/env bash
set -uo pipefail
. "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
# 4.2 CI as the referee: CI runs the same command you run. MIXED: the hosted run itself is not done here.
banner "the workflow CI uses"
cat "$ROOT/project/.github/workflows/ci.yml"
banner "the command it runs, run locally"
d=$(new_work ci)
stage_into "$d" n-green
make -C "$d" test || LESSON_STATUS=FAILED
grep -q 'make test' "$ROOT/project/.github/workflows/ci.yml" || LESSON_STATUS=FAILED
echo "NOT RUN: the hosted workflow (no remote exists)"
finish
