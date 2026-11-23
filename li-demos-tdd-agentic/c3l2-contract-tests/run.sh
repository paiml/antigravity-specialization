#!/usr/bin/env bash
set -uo pipefail
. "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
# 3.2 Contract tests from a YAML spec, plus a validation of the formal contract.
d=$(new_work contract)
stage_into "$d" n-green
"$ROOT/scripts/contract-test.sh" "$d" "$ROOT/contracts/slugify-cases.yaml" || LESSON_STATUS=FAILED
banner "pv validate on the formal contract"
if command -v pv >/dev/null 2>&1; then
  pv validate "$ROOT/contracts/slugify-v1.yaml" 2>&1 | tail -n 3 || LESSON_STATUS=FAILED
else
  echo "pv not installed here: contract validation NOT RUN"
fi
finish
