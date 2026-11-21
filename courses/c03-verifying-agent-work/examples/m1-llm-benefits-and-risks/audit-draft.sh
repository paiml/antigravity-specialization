#!/bin/bash
# Audits an LLM-generated shell script for common failure modes:
#   1. missing or empty file
#   2. invalid bash syntax
#   3. missing strict error mode (set -e / set -euo pipefail)
#   4. leftover placeholders (TODO / FIXME / PLACEHOLDER)
#   5. masked failures (|| true)
#   6. hallucinated SOURCE_FILE="..." paths that do not exist
#
# Usage: ./audit-draft.sh <script_path> [base_dir]

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="${1:-}"
BASE_DIR="${2:-$HERE}"

if [ -z "$SCRIPT" ]; then
    echo "Usage: $0 <script_path> [base_dir]" >&2
    exit 1
fi

if [ ! -f "$SCRIPT" ] || [ ! -s "$SCRIPT" ]; then
    echo "FAIL: script is missing or empty: $SCRIPT" >&2
    exit 1
fi

errors=0

if ! bash -n "$SCRIPT"; then
    echo "FAIL: syntax error in $SCRIPT" >&2
    errors=$((errors + 1))
fi

if ! grep -Eq '^[[:space:]]*set[[:space:]]+-e' "$SCRIPT"; then
    echo "FAIL: missing 'set -e' or 'set -euo pipefail' in $SCRIPT" >&2
    errors=$((errors + 1))
fi

if grep -Eq '(TODO|FIXME|PLACEHOLDER)' "$SCRIPT"; then
    echo "FAIL: unfinished placeholder marker found in $SCRIPT" >&2
    errors=$((errors + 1))
fi

if grep -Eq '\|\|[[:space:]]*true([[:space:]]|$)' "$SCRIPT"; then
    echo "FAIL: error-masking '|| true' found in $SCRIPT" >&2
    errors=$((errors + 1))
fi

src_paths="$(sed -n 's/^[[:space:]]*SOURCE_FILE="\([^"]*\)".*/\1/p' "$SCRIPT")"
if [ -n "$src_paths" ]; then
    while IFS= read -r rel_path; do
        [ -n "$rel_path" ] || continue
        if [ ! -s "$BASE_DIR/$rel_path" ]; then
            echo "FAIL: referenced SOURCE_FILE missing or empty: $BASE_DIR/$rel_path" >&2
            errors=$((errors + 1))
        fi
    done <<EOF
$src_paths
EOF
fi

if [ "$errors" -ne 0 ]; then
    echo "Audit failed with $errors error(s)." >&2
    exit 1
fi

echo "Audit passed: $SCRIPT"
