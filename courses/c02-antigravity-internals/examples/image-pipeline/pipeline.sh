#!/bin/bash
# The whole job in one command: remove the star, then transpose what is left.
#
# The two stages are the two scripts beside this one, called in order. The
# intermediate never lands next to your input -- it goes to a temp directory
# that is removed on exit, so running this twice leaves exactly one new file.

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

HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Stage 1 -- remove the star and its shadow.
"$HERE/remove_star.sh" "$INPUT_FILE" "$WORK/nostar.png" >/dev/null

# Stage 2 -- transpose the result.
"$HERE/transpose.sh" "$WORK/nostar.png" "$OUTPUT_FILE"
