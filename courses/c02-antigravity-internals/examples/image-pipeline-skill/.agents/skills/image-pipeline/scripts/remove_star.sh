#!/bin/bash
# Removes the star and its shadow from the image using ImageMagick

INPUT_FILE="$1"
OUTPUT_FILE="$2"

if [ -z "$INPUT_FILE" ] || [ -z "$OUTPUT_FILE" ]; then
    echo "Usage: $0 <input_image> <output_image>"
    exit 1
fi

# The background color is #EFE9DF
# The first polygon covers the star and its pole, carefully tracing the top of the pyramid.
# The second polygon covers the shadow on the ground on the left.
convert "$INPUT_FILE" -fill "#EFE9DF" \
    -draw "polygon 291,127 275,139 255,154 230,154 230,10 360,10 360,154 330,154 310,140" \
    -draw "polygon 139,246 74,296 0,296 0,200 139,200" \
    "$OUTPUT_FILE"

echo "Processed image saved to $OUTPUT_FILE"
