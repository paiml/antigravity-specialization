#!/usr/bin/env bash
set -uo pipefail
. "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
# 3.3 Property tests: an implementation that passes every example and still breaks a property.
for s in narrow n-green; do
  banner "stage $s"
  d=$(new_work "$s")
  stage_into "$d" "$s"
  CASES="$ROOT/stages/green/tests/cases.txt" run_tests "$d" | tail -n 1
  (cd "$d" && bash tests/property.sh | tail -n 2) && echo "=> properties hold" || echo "=> property broken"
done
finish
