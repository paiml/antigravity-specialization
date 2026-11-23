#!/usr/bin/env bash
# review-diff.sh OLD_DIR NEW_DIR [impl|tests]: the first question to ask about an agent's change.
#   impl   the task was "make it pass": tests/cases.txt must be unchanged
#   tests  the task was "write a failing test": src/slugify.sh must be unchanged
# Exit 1 when the change touched what the task said not to touch.
set -uo pipefail
old="$1"
new="$2"
mode="${3:-impl}"
src=0
tst=0
cmp -s "$old/src/slugify.sh" "$new/src/slugify.sh" || src=1
cmp -s "$old/tests/cases.txt" "$new/tests/cases.txt" || tst=1
echo "task: $mode; src changed: $src; tests changed: $tst"
if [ "$mode" = impl ] && [ "$tst" -eq 1 ]; then
  echo "REVIEW: the tests changed during an implementation task; read the test edit first"
  exit 1
fi
if [ "$mode" = tests ] && [ "$src" -eq 1 ]; then
  echo "REVIEW: the source changed during a test-writing task"
  exit 1
fi
echo "review-diff ok"
