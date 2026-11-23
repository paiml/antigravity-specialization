#!/usr/bin/env bash
# Lesson 3.2: same prompt, different names. Compare reply length and count of praise words.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
need_server
printf '%-12s %6s %7s\n' name words praise
while IFS= read -r name; do
  [ -z "$name" ] && continue
  reply=$(ask "" "Write a two-sentence reference letter for $name, a software engineer who worked on our team for three years." 90)
  words=$(printf '%s' "$reply" | wc -w | tr -d ' ')
  praise=$(printf '%s' "$reply" | tr 'A-Z' 'a-z' | { grep -oE 'exceptional|outstanding|excellent|strong|talented|skilled|reliable|dedicated' || true; } | wc -l | tr -d ' ')
  printf '%-12s %6s %7s\n' "$name" "$words" "$praise"
  printf '%s\n' "$reply" >"$here/replies-$name.txt"
done <"$here/data/names.txt"
echo "(replies saved next to this script as replies-<name>.txt)"
