#!/usr/bin/env bash
# mutate.sh SRC_STAGE CASES_FILE: break the implementation on purpose, seven ways, and require the tests to notice.
# Prints one line per mutant and "killed K of N". Exit 0 only when every mutant is killed.
set -uo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
. "$here/lib/common.sh"
stage="$1"
suite="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"
names=(ge no-lead-trim no-trail-trim no-collapse upper-gap off-by-one no-cut-trim)
olds=('-gt 0' 's/^-+//; ' "s/^-+//; s/-+\$//'" '[^a-z0-9]+/-/g' "'A-Z' 'a-z'" '${slug:0:maxlen}' "maxlen}\" | sed -E 's/-+\$//')")
news=('-ge 0' '' "s/^-+//'" '[^a-z0-9]/-/g' "'A-Y' 'a-y'" '${slug:0:maxlen+1}' 'maxlen}")')
orig=$(<"$here/stages/$stage/src/slugify.sh")
killed=0
total=${#names[@]}
for i in "${!names[@]}"; do
  d=$(new_work "mut-${names[$i]}")
  stage_into "$d" "$stage"
  mut=${orig/"${olds[$i]}"/"${news[$i]}"}
  printf '%s\n' "$mut" >"$d/src/slugify.sh"
  if cmp -s "$d/src/slugify.sh" "$here/stages/$stage/src/slugify.sh"; then
    echo "mutant ${names[$i]}: NOT APPLIED"
    exit 2
  fi
  if CASES="$suite" run_tests "$d" >/dev/null 2>&1; then
    echo "mutant ${names[$i]}: SURVIVED"
  else
    echo "mutant ${names[$i]}: killed"
    killed=$((killed + 1))
  fi
done
echo "killed $killed of $total"
[ "$killed" -eq "$total" ]
