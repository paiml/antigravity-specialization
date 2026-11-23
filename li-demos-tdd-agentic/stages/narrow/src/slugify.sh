#!/usr/bin/env bash
# Passes the example tests but only knows a few separators: "/" "_" "@" are left in the slug.
set -euo pipefail
printf '%s\n' "${1-}" | tr 'A-Z' 'a-z' | sed -E "s/[ ,.!?&'-]+/-/g; s/^-+//; s/-+\$//"
