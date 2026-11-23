#!/usr/bin/env bash
# spec-lint.sh DIR: every rule (R1, R2, ...) in spec/slugify.md has an Example and a tagged test.
set -uo pipefail
dir="$1"
rules=$(grep -oE '^- R[0-9]+' "$dir/spec/slugify.md" | cut -c3-)
bad=0
for r in $rules; do
  if ! grep -E "^- $r " "$dir/spec/slugify.md" | grep -q 'Example:'; then
    echo "NO EXAMPLE: $r"
    bad=$((bad + 1))
  fi
  if ! grep -Eq "^# $r( |$)" "$dir/tests/cases.txt"; then
    echo "NO TEST TAG: $r"
    bad=$((bad + 1))
  fi
done
echo "spec-lint: $(echo "$rules" | wc -w | tr -d ' ') rules, $bad problems"
[ "$bad" -eq 0 ]
