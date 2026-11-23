#!/usr/bin/env bash
# slugify [-n MAX] TEXT (refactored: same behaviour, one small function per rule).
set -euo pipefail

normalize() {
  tr 'A-Z' 'a-z' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

cut_to() {
  local max="$1" slug="$2"
  printf '%s' "${slug:0:max}" | sed -E 's/-+$//'
}

maxlen=0
if [ "${1-}" = "-n" ]; then
  maxlen="$2"
  shift 2
fi
slug=$(printf '%s\n' "${1-}" | normalize)
if [ "$maxlen" -gt 0 ]; then
  slug=$(cut_to "$maxlen" "$slug")
fi
printf '%s\n' "$slug"
