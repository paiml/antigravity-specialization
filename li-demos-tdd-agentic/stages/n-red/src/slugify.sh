#!/usr/bin/env bash
# slugify TEXT: lowercase, runs of other characters become one "-", no leading or trailing "-".
set -euo pipefail
text="${1-}"
printf '%s\n' "$text" | tr 'A-Z' 'a-z' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
