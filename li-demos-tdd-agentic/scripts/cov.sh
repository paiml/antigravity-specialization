#!/usr/bin/env bash
# cov.sh TRACE FILE SUFFIX: line coverage of one shell file from a bash xtrace log.
# Executable lines = non-blank, non-comment lines that are not bare keywords (fi, done, else, ;;, }, case labels).
# This is an approximation: it counts lines, not branches. Prints "FILE covered/total pct%" and the missed lines.
set -uo pipefail
trace="$1"
file="$2"
suffix="$3"
exec_lines=$(awk '
  { line = $0; sub(/^[ \t]+/, "", line) }
  line == "" || line ~ /^#/ { next }
  cont { cont = (line ~ /\\$/); next }
  { cont = (line ~ /\\$/) }
  line ~ /^(fi|done|esac|else|then|do)([ ;<>].*)?$/ { next }
  line ~ /^(;;|\}|\{|\))/ { next }
  line ~ /^[^ ()]+\)$/ { next }
  line ~ /^[A-Za-z_][A-Za-z_0-9]*\(\) *\{$/ { next }
  { print NR }
' "$file")
hit=$(grep -o 'COV|[^|]*|[0-9]*|' "$trace" | awk -F'|' -v suf="/$suffix" '{ p = "/" $2; if (substr(p, length(p) - length(suf) + 1) == suf) print $3 }' | sort -n | uniq)
total=0
covered=0
missed=''
for n in $exec_lines; do
  total=$((total + 1))
  if printf '%s\n' "$hit" | grep -qx "$n"; then covered=$((covered + 1)); else missed="$missed $n"; fi
done
pct=100
[ "$total" -gt 0 ] && pct=$((covered * 100 / total))
echo "$covered $total $pct${missed:+ missed:$missed}"
