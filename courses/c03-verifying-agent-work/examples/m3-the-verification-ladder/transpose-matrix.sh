#!/bin/bash
# Transposes a whitespace-delimited rectangular matrix: out[c, r] = in[r, c].

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
    if (NF != cols) { print "FAIL: ragged matrix row " NR > "/dev/stderr"; exit 1 }
    for (c = 1; c <= NF; c++) a[NR, c] = $c
    rows = NR
} END {
    if (rows == 0 || cols == 0) exit 1
    for (c = 1; c <= cols; c++) {
        for (r = 1; r <= rows; r++) {
            printf "%s%s", a[r, c], (r == rows ? "\n" : " ")
        }
    }
}' "$INPUT_FILE" > "$OUTPUT_FILE"
