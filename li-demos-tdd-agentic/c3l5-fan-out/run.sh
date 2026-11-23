#!/usr/bin/env bash
set -uo pipefail
. "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
# 3.5 Fan out: three agents attempt the same task in separate copies; one test suite picks the winner.
dirs=()
for i in 1 2 3; do
  d=$(new_work "fan$i")
  stage_into "$d" n-red
  dirs+=("$d")
done
for d in "${dirs[@]}"; do
  agy_step "$d" "$ROOT/prompts/fan-out.md" >"$d/.step-log" 2>&1 &
done
wait
status=$(cat "${dirs[0]}/.agy-status")
if [ "$status" = RAN ]; then
  banner "one test suite, three candidates"
  win=0
  for d in "${dirs[@]}"; do
    if "$ROOT/scripts/verify.sh" "$d" green n-red; then win=$((win + 1)); fi
  done
  echo "$win of 3 candidates pass"
  [ "$win" -ge 1 ] || LESSON_STATUS=FAILED
elif [ "$status" = FAILED ]; then
  LESSON_STATUS=FAILED
else
  LESSON_STATUS=$status
  banner "agents did not run ($status); the same suite on three REFERENCE candidates (hand-written, NOT agent output)"
  win=0
  for s in n-green n-refactor wrong; do
    r=$(new_work "ref-$s")
    stage_into "$r" "$s"
    echo "candidate $s:"
    if "$ROOT/scripts/verify.sh" "$r" green n-red; then win=$((win + 1)); fi
  done
  echo "$win of 3 candidates pass"
  [ "$win" -eq 2 ] || LESSON_STATUS=FAILED
fi
finish
