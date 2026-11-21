#!/bin/bash
# Contrasts unverified single-shot/exit-code checks with contract-verified work.
# Usage: ./evolve.sh [config_file] [output_report]

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="${1:-$HERE/sample-config.env}"
OUTPUT_FILE="${2:-}"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "error: config file not found: $CONFIG_FILE" >&2
    exit 1
fi

if [ ! -s "$CONFIG_FILE" ]; then
    echo "error: config file is empty: $CONFIG_FILE" >&2
    exit 1
fi

extract_key() {
    local key="$1"
    awk -F= -v k="$key" '$1 == k { val = substr($0, length(k) + 2) } END { print val }' "$CONFIG_FILE"
}

SERVICE_NAME="$(extract_key "SERVICE_NAME")"
MAX_RETRIES="$(extract_key "MAX_RETRIES")"
MODE="$(extract_key "MODE")"

errors=0

if ! printf '%s' "$SERVICE_NAME" | grep -Eq '^[a-zA-Z0-9_-]+$'; then
    echo "error: invalid or missing SERVICE_NAME: [$SERVICE_NAME]" >&2
    errors=$((errors + 1))
fi

if ! printf '%s' "$MAX_RETRIES" | grep -Eq '^[1-9][0-9]*$' || [ "$MAX_RETRIES" -gt 10 ]; then
    echo "error: MAX_RETRIES must be an integer 1..10, got [$MAX_RETRIES]" >&2
    errors=$((errors + 1))
fi

if [ "$MODE" != "strict" ] && [ "$MODE" != "warn" ]; then
    echo "error: MODE must be 'strict' or 'warn', got [$MODE]" >&2
    errors=$((errors + 1))
fi

if [ "$errors" -ne 0 ]; then
    exit 1
fi

echo "Stage 1 (autocomplete): text only, no execution check"
echo "Stage 2 (exit-code check): command exited 0, artifact contents unchecked"
echo "Stage 3 (verified agentic step): SERVICE_NAME=$SERVICE_NAME MAX_RETRIES=$MAX_RETRIES MODE=$MODE"

if [ -n "$OUTPUT_FILE" ]; then
    cat > "$OUTPUT_FILE" <<EOF
SERVICE_NAME=$SERVICE_NAME
MAX_RETRIES=$MAX_RETRIES
MODE=$MODE
VERIFIED=true
EOF
fi
