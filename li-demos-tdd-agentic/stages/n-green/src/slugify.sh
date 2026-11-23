#!/usr/bin/env bash
# slugify [-n MAX] TEXT: lowercase, runs of other characters become one "-", trimmed, optional cut.
set -euo pipefail
maxlen=0
if [ "${1-}" = "-n" ]; then
  maxlen="$2"
  shift 2
fi
text="${1-}"
slug=$(printf '%s\n' "$text" | tr 'A-Z' 'a-z' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')
if [ "$maxlen" -gt 0 ]; then
  slug=$(printf '%s' "${slug:0:maxlen}" | sed -E 's/-+$//')
fi
printf '%s\n' "$slug"
