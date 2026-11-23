#!/usr/bin/env bash
# Lesson 4.1: a small test set. Each line of data/eval.jsonl has a question and a substring the answer must contain.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
need_server
threshold="${THRESHOLD:-60}"
pass=0 total=0
while IFS= read -r row; do
  [ -z "$row" ] && continue
  q=$(printf '%s' "$row" | jq -r '.q')
  want=$(printf '%s' "$row" | jq -r '.expect')
  got=$(ask "Answer as briefly as possible." "$q" 24)
  total=$((total + 1))
  if printf '%s' "$got" | grep -qiF -- "$want"; then
    pass=$((pass + 1)); verdict=PASS
  else
    verdict=FAIL
  fi
  printf '%s  q=%s  expect=%s  got=%s\n' "$verdict" "$q" "$want" "$(printf '%s' "$got" | tr '\n' ' ')"
done <"$here/data/eval.jsonl"
pct=$((pass * 100 / total))
echo "score: $pass/$total = $pct% (gate: $threshold%)"
if [ "$pct" -lt "$threshold" ]; then echo "GATE FAILED: do not ship this model for this task"; exit 1; fi
echo "gate passed"
