#!/usr/bin/env bash
set -uo pipefail
. "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
# 1.1 Red, green, refactor: the same test command in three states.
for s in stub green n-refactor; do
  banner "stage $s"
  d=$(new_work "$s")
  stage_into "$d" "$s"
  if run_tests "$d" | tail -n 3; then echo "=> GREEN"; else echo "=> RED"; fi
done
finish
