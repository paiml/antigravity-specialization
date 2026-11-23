#!/usr/bin/env bash
# Example tests: each line of cases.txt is MAX|input|expected ("-" means no limit).
set -uo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
cases="${CASES:-$here/tests/cases.txt}"
pass=0
fail=0
while IFS='|' read -r n input want; do
  case "$n" in
    '' | '#'*) continue ;;
  esac
  if [ "$n" = "-" ]; then
    got=$("$here/src/slugify.sh" "$input" 2>&1)
  else
    got=$("$here/src/slugify.sh" -n "$n" "$input" 2>&1)
  fi
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    echo "FAIL n=$n input='$input' want='$want' got='$got'"
  fi
done <"$cases"
echo "examples: passed=$pass failed=$fail"
if [ "$pass" -eq 0 ]; then
  echo "FAIL: no tests ran"
  exit 1
fi
[ "$fail" -eq 0 ]
