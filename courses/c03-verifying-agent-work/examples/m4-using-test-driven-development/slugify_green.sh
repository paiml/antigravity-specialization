#!/bin/bash
# GREEN implementation: satisfies all 6 TDD specification cases.

set -euo pipefail

RAW="${1:-}"
if [ -z "$RAW" ]; then
    echo "error: input cannot be empty" >&2
    exit 1
fi

SLUG="$(printf '%s' "$RAW" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
if [ -z "$SLUG" ]; then
    echo "error: input produced empty slug" >&2
    exit 1
fi

printf '%s\n' "$SLUG"
