#!/bin/bash
set -euo pipefail

INPUT="${1:-}"
OUTPUT="${2:-}"

[ -n "$INPUT" ] && [ -n "$OUTPUT" ] || { echo "Usage: $0 <input> <output>" >&2; exit 2; }
[ -s "$INPUT" ] || { echo "FAIL: input missing or empty: $INPUT" >&2; exit 1; }

LINES="$(wc -l < "$INPUT" | tr -d ' ')"
WORDS="$(wc -w < "$INPUT" | tr -d ' ')"

mkdir -p "$(dirname "$OUTPUT")"
printf 'lines=%s\nwords=%s\n' "$LINES" "$WORDS" > "$OUTPUT"
