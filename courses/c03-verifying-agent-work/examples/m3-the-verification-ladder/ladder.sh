#!/bin/bash
# Three-rung Verification Ladder for matrix transpose candidates.

set -euo pipefail

INPUT_FILE="${1:-}"
CANDIDATE="${2:-}"

if [ -z "$INPUT_FILE" ] || [ -z "$CANDIDATE" ]; then
    echo "Usage: $0 <input-matrix> <candidate-script>" >&2
    exit 1
fi
[ -s "$INPUT_FILE" ] || { echo "FAIL: missing or empty input: $INPUT_FILE" >&2; exit 1; }
[ -s "$CANDIDATE" ] || { echo "FAIL: missing or empty candidate script: $CANDIDATE" >&2; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

shape() {
    awk '{
        if (NR == 1) c = NF
        else if (NF != c) { print "RAGGED"; exit 0 }
        r = NR
    } END { if (r == 0) print "0x0"; else printf "%dx%d\n", r, c }' "$1"
}

OUT="$WORK/out.txt"
ROUNDTRIP="$WORK/roundtrip.txt"

bash "$CANDIDATE" "$INPUT_FILE" "$OUT"

# Rung 1: Existence and non-empty
if [ ! -s "$OUT" ]; then
    echo "Rung 1 FAIL: output file is missing or empty" >&2
    exit 1
fi
echo "  Rung 1 PASS: non-empty output produced"

# Rung 2: Shape check (R x C -> C x R)
IN_SHAPE="$(shape "$INPUT_FILE")"
OUT_SHAPE="$(shape "$OUT")"
WANT_SHAPE="$(printf '%s\n' "$IN_SHAPE" | awk -Fx '{printf "%dx%d\n", $2, $1}')"
if [ "$OUT_SHAPE" != "$WANT_SHAPE" ]; then
    echo "Rung 2 FAIL: expected shape $WANT_SHAPE, got $OUT_SHAPE" >&2
    exit 1
fi
echo "  Rung 2 PASS: shape is $OUT_SHAPE"

# Rung 3: Semantic invariant (involution + top-left corner preserved)
bash "$CANDIDATE" "$OUT" "$ROUNDTRIP"
if ! diff -u "$INPUT_FILE" "$ROUNDTRIP" >/dev/null 2>&1; then
    echo "Rung 3 FAIL: applying transform twice did not restore original input" >&2
    exit 1
fi
IN_TL="$(awk 'NR==1 {print $1; exit}' "$INPUT_FILE")"
OUT_TL="$(awk 'NR==1 {print $1; exit}' "$OUT")"
if [ "$IN_TL" != "$OUT_TL" ]; then
    echo "Rung 3 FAIL: top-left element changed ($IN_TL -> $OUT_TL)" >&2
    exit 1
fi
echo "  Rung 3 PASS: involution and diagonal invariant hold"
