#!/usr/bin/env bash
# Property tests: facts that must hold for every input, checked on a fixed list plus seeded random text.
set -uo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
slug="$here/src/slugify.sh"
RANDOM=42
chars='abcXYZ019 ,.!?-_/@#:&'
inputs=('' 'a' 'Hello World' '--x--' '___' 'A/B_C')
for _ in $(seq 1 60); do
  s=''
  len=$((RANDOM % 14))
  for _ in $(seq 1 "$len"); do k=$((RANDOM % ${#chars} + 1)); s="$s$(printf %s "$chars" | cut -c"$k")"; done
  inputs+=("$s")
done
fail=0
for s in "${inputs[@]}"; do
  out=$("$slug" "$s" 2>&1)
  if [ -n "$out" ] && ! printf '%s' "$out" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$'; then
    echo "FAIL shape: '$s' -> '$out'"
    fail=$((fail + 1))
  fi
  again=$("$slug" "$out" 2>&1)
  if [ "$again" != "$out" ]; then
    echo "FAIL idempotence: '$s' -> '$out' -> '$again'"
    fail=$((fail + 1))
  fi
done
echo "properties: inputs=${#inputs[@]} failures=$fail"
[ "$fail" -eq 0 ]
