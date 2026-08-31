#!/bin/bash
# Transposes an image: mirrors it across the diagonal running from the
# top-left corner. This is a reflection, not a rotation -- the top-left
# pixel stays where it is. A W x H image becomes H x W.
#
# Not the same as -rotate 90. Both change 502x460 into 460x502, so a check
# that only compares dimensions passes on either one. They differ by
# 97024 pixels, because -rotate 90 is this operation plus a left-right flip.

set -euo pipefail

INPUT_FILE="${1:-}"
OUTPUT_FILE="${2:-}"

if [ -z "$INPUT_FILE" ] || [ -z "$OUTPUT_FILE" ]; then
    echo "Usage: $0 <input_image> <output_image>" >&2
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "error: no such file: $INPUT_FILE" >&2
    exit 1
fi

# ImageMagick 7 installs 'magick'; ImageMagick 6 installs 'convert'.
# Arrays, not strings: an unquoted string variable does not word-split in zsh.
if command -v magick >/dev/null 2>&1; then
    IM_CONVERT=(magick)
    IM_IDENTIFY=(magick identify)
elif command -v convert >/dev/null 2>&1; then
    IM_CONVERT=(convert)
    IM_IDENTIFY=(identify)
else
    echo "error: ImageMagick not found; need 'magick' (IM7) or 'convert' (IM6)" >&2
    exit 127
fi

# +repage discards the page geometry -transpose inherits from the source,
# so the output describes its own size rather than the size it came from.
"${IM_CONVERT[@]}" "$INPUT_FILE" -transpose +repage "$OUTPUT_FILE"

echo "Transposed $("${IM_IDENTIFY[@]}" -format '%wx%h' "$INPUT_FILE") -> $("${IM_IDENTIFY[@]}" -format '%wx%h' "$OUTPUT_FILE"): $OUTPUT_FILE"
