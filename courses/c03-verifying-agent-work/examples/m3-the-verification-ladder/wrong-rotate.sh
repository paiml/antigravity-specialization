#!/bin/bash
# Deliberately wrong implementation: 90-degree clockwise rotation.
# Produces the exact same 2x3 shape as transpose on a 3x2 matrix,
# so dimension-only checks pass even though the values are rotated.

set -euo pipefail

INPUT_FILE="${1:-}"
OUTPUT_FILE="${2:-}"

if [ -z "$INPUT_FILE" ] || [ -z "$OUTPUT_FILE" ]; then
    echo "Usage: $0 <input-matrix> <output-matrix>" >&2
    exit 1
fi
[ -s "$INPUT_FILE" ] || { echo "FAIL: missing or empty input: $INPUT_FILE" >&2; exit 1; }

awk '{
    if (NR == 1) cols = NF
    for (c = 1; c <= NF; c++) a[NR, c] = $c
    rows = NR
} END {
    for (c = 1; c <= cols; c++) {
        for (r = rows; r >= 1; r--) {
            printf "%s%s", a[r, c], (r == 1 ? "\n" : " ")
        }
    }
}' "$INPUT_FILE" > "$OUTPUT_FILE"
