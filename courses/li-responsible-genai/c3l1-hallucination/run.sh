#!/usr/bin/env bash
# Lesson 3.1: ask without a source, then check every capitalized word and number in the answer against the source file.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
need_server
src="$here/data/facts.txt"

# unsupported ANSWER SOURCEFILE -> prints each capitalized word or number of the answer that the source lacks.
unsupported() {
  printf '%s' "$1" | tr -c 'A-Za-z0-9\n' ' ' | tr ' ' '\n' | grep -E '^([A-Z][a-z]{2,}|[0-9]+)$' | sort -u |
    while IFS= read -r tok; do
      if ! grep -qiF -- "$tok" "$2"; then echo "$tok"; fi
    done
}

check() {
  local label="$1" q="$2" ans bad
  ans=$(ask "Answer in one short sentence." "$q" 48)
  echo "[$label] Q: $q"
  echo "[$label] A: $ans"
  bad=$(unsupported "$ans" "$src" | tr '\n' ' ')
  if [ -n "$bad" ]; then echo "[$label] SOURCE CHECK: UNSUPPORTED -> $bad"; else echo "[$label] SOURCE CHECK: every name and number appears in the source"; fi
  echo
}

check "no-source" "Who founded the company Brightloop Analytics and in what year?"
check "with-source" "Using only this source, who founded Brightloop Analytics and when? Source: $(cat "$src")"
