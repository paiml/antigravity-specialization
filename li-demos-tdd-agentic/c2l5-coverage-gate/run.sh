#!/usr/bin/env bash
set -uo pipefail
. "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
# 2.5 Coverage as a gate: line coverage of src/slugify.sh under two test sets.
cov_of() { # CASES_FILE LABEL
  local d trace
  d=$(new_work cov)
  stage_into "$d" n-green
  trace="$d/trace.log"
  : >"$trace"
  exec 9>>"$trace"
  env CASES="$1" BASH_XTRACEFD=9 SHELLOPTS=xtrace PS4='+COV|${BASH_SOURCE[0]}|${LINENO}|' bash "$d/tests/run.sh" >/dev/null 2>&1
  exec 9>&-
  printf '%s: ' "$2"
  "$ROOT/scripts/cov.sh" "$trace" "$d/src/slugify.sh" src/slugify.sh
}
banner "base tests only (no -n cases)"
cov_of "$ROOT/stages/green/tests/cases.txt" "base tests"
banner "all tests (with R5 cases)"
out=$(cov_of "$ROOT/stages/n-green/tests/cases.txt" "all tests")
echo "$out"
case "$out" in
  *' 100 '* | *' 100') echo "GATE: 100 percent, pass" ;;
  *) echo "GATE: below 100 percent; say why or add tests"; LESSON_STATUS=FAILED ;;
esac
finish
