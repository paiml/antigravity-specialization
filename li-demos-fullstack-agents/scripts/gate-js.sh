#!/usr/bin/env bash
# Run node --test in every milestone, and node's line coverage (100% required) on the finished app.
# Prints how many milestones it ran so "0 milestones" cannot pass.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
. lib/common.sh
need_node || exit 1
n=0
bad=0
for dir in milestones/*/; do
  [ -f "$dir/package.json" ] || continue
  n=$((n + 1))
  if (cd "$dir" && node --test >/dev/null 2>&1); then
    echo "js ok    $dir"
  else
    echo "js FAIL  $dir"
    bad=1
  fi
done
echo "js: $n milestones"
if [ "$n" -eq 0 ]; then
  echo "FAIL ran 0 milestones"
  exit 1
fi
if ! (cd milestones/v1.0.0 && make cover 2>&1 | grep -E '^# (tests|pass|fail)|all files'); then
  echo "FAIL coverage run"
  bad=1
fi
if [ "$bad" -ne 0 ]; then exit 1; fi
echo "js OK"
