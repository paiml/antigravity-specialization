#!/usr/bin/env bash
# Lesson 2.4: small RAG on local text. Keyword retrieval (grep -c) picks the best file, the model answers from it.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
need_server
q="${1:-How many days of paid leave do new employees get?}"
terms=$(printf '%s' "$q" | tr 'A-Z' 'a-z' | tr -cs 'a-z' '\n' | awk 'length($0) > 3')
best="" bestn=0
for f in "$here"/docs/*.txt; do
  n=0
  for t in $terms; do
    c=$(grep -ic -- "$t" "$f" || true)
    n=$((n + c))
  done
  echo "score $n  $(basename "$f")"
  if [ "$n" -gt "$bestn" ]; then bestn=$n; best=$f; fi
done
if [ -z "$best" ]; then echo "no document matched: refusing to guess"; exit 0; fi
echo "--- using $(basename "$best")"
ask "Answer only from the context. If the context does not contain the answer, say: not in the documents." "Context:
$(cat "$best")

Question: $q" 80
