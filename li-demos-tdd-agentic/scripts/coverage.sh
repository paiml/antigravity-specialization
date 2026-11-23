#!/usr/bin/env bash
# coverage.sh: run the offline tests under bash xtrace and report line coverage per shell file.
set -uo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
cd "$here" || exit 1
trace="$here/.run/trace.log"
mkdir -p "$here/.run"
: >"$trace"
exec 9>>"$trace"
env BASH_XTRACEFD=9 SHELLOPTS=xtrace PS4='+COV|${BASH_SOURCE[0]}|${LINENO}|' bash tests/run-tests.sh >"$here/.run/coverage-tests.out" 2>&1
echo "tests exit code: $?"
exec 9>&-
tc=0
tt=0
for f in lib/common.sh scripts/verify.sh scripts/spec-lint.sh scripts/contract-test.sh scripts/mutate.sh scripts/review-diff.sh scripts/plan-check.sh scripts/cov.sh scripts/capture.sh project/tests/run.sh project/tests/property.sh c*/run.sh; do
  suffix="$f"
  case "$f" in
    project/*) suffix="${f#project/}" ;;
  esac
  read -r c t p rest <<<"$(scripts/cov.sh "$trace" "$f" "$suffix")"
  echo "$f $c/$t ${p}% $rest"
  tc=$((tc + c))
  tt=$((tt + t))
done
echo "TOTAL $tc/$tt lines"
