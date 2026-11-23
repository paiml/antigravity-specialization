#!/usr/bin/env bash
# Plausible but wrong: every odd character becomes its own "-" and nothing is trimmed.
set -euo pipefail
printf '%s\n' "${1-}" | tr 'A-Z' 'a-z' | sed -E 's/[^a-z0-9]/-/g'
