#!/bin/bash
# Verifies that an image was correctly transposed (not rotated)

INPUT_FILE="$1"
OUTPUT_FILE="$2"

if [ -z "$INPUT_FILE" ] || [ -z "$OUTPUT_FILE" ]; then
    echo "Usage: $0 <input_image> <transposed_image>"
    exit 1
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Verifying transpose operation..."

# 1. Check dimensions
IN_W=$(identify -format "%w" "$INPUT_FILE")
IN_H=$(identify -format "%h" "$INPUT_FILE")
OUT_W=$(identify -format "%w" "$OUTPUT_FILE")
OUT_H=$(identify -format "%h" "$OUTPUT_FILE")

if [ "$IN_W" != "$OUT_H" ] || [ "$IN_H" != "$OUT_W" ]; then
    echo "FAIL: Dimensions do not match. Input is ${IN_W}x${IN_H}, output is ${OUT_W}x${OUT_H}."
    exit 1
fi
echo "PASS: Dimensions are swapped (${IN_W}x${IN_H} -> ${OUT_W}x${OUT_H})."

# 2. Check that transposing the output returns the input
convert "$OUTPUT_FILE" -transpose "$TMP_DIR/double_transpose.png"
DIFF1=$(compare -metric AE "$INPUT_FILE" "$TMP_DIR/double_transpose.png" null: 2>&1)
if [ "$DIFF1" != "0" ]; then
    echo "FAIL: Transposing the output does not reproduce the input (differ by $DIFF1 pixels)."
    exit 1
fi
echo "PASS: Transposing the output exactly reproduces the input."

# 3. Check that it is not just a -rotate 90
convert "$INPUT_FILE" -rotate 90 "$TMP_DIR/rotated.png"
DIFF2=$(compare -metric AE "$OUTPUT_FILE" "$TMP_DIR/rotated.png" null: 2>&1)
if [ "$DIFF2" == "0" ]; then
    echo "FAIL: The output is identical to -rotate 90."
    exit 1
fi
echo "PASS: The output differs from a 90-degree rotation (by $DIFF2 pixels)."

echo "All checks passed."
