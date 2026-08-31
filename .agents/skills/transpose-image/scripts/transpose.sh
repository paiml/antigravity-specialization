#!/bin/bash
# Transpose the input image

INPUT_FILE="$1"
OUTPUT_FILE="$2"

if [ -z "$INPUT_FILE" ] || [ -z "$OUTPUT_FILE" ]; then
    echo "Usage: $0 <input_image> <output_image>"
    exit 1
fi

convert "$INPUT_FILE" -transpose "$OUTPUT_FILE"

echo "Transposed image saved to $OUTPUT_FILE"
