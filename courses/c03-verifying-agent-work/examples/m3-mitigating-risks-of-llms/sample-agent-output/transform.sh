#!/bin/bash
# Clean sample deliverable: normalizes whitespace-delimited records in place.

set -euo pipefail

INPUT_FILE="${1:-}"
if [ -z "$INPUT_FILE" ] || [ ! -f "$INPUT_FILE" ]; then
    echo "Usage: $0 <input-file>" >&2
    exit 1
fi

awk 'NF > 0 { $1 = $1; print }' "$INPUT_FILE"
