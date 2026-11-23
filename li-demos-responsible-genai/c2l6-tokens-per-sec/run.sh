#!/usr/bin/env bash
# Lesson 2.6: measure tokens per second through the server (completion_tokens / wall seconds).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
need_server
for i in 1 2 3; do
  start=$EPOCHREALTIME
  out=$(chat_raw "" "Write one sentence about the sea." 48)
  end=$EPOCHREALTIME
  toks=$(printf '%s' "$out" | jq -r '.usage.completion_tokens')
  awk -v t="$toks" -v s="$start" -v e="$end" -v i="$i" 'BEGIN{printf "run %d: %d tokens in %.2f s = %.1f tok/s\n", i, t, e-s, t/(e-s)}'
done
