#!/usr/bin/env bash
# Lesson 1.1.3: The agent drafts the architecture; you review it.
# RUNS: a review checklist applied to docs/ARCHITECTURE.md (every file it lists must be in the planned layout,
# and the failure-modes section must exist). BLOCKED when agy has no quota: the draft itself.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
new_workdir
copy_ms v1.0.0 "$WORK/final"
agy_step "$here/prompts/draft-architecture.md" plan "$WORK/final"
say "review 1: every file named in the Files table exists in the finished app"
bad=0
for f in $(grep -oE '^\| `[^`]+`' "$WORK/final/docs/ARCHITECTURE.md" | tr -d '|` '); do
  case "$f" in
    *,*) continue ;;
  esac
  if [ -e "$WORK/final/$f" ]; then echo "ok    $f"; else echo "FAIL  $f is described but missing"; bad=1; fi
done
say "review 2: the failure modes section has at least three bullets"
n=$(sed -n '/^## Failure modes/,$p' "$WORK/final/docs/ARCHITECTURE.md" | grep -c '^- ')
echo "failure modes listed: $n"
if [ "$n" -lt 3 ]; then bad=1; fi
say "review 3: a draft that invents a file is caught"
printf '| `cache.js` | A cache nobody asked for. |\n' >>"$WORK/final/docs/ARCHITECTURE.md"
if [ -e "$WORK/final/cache.js" ]; then echo "FAIL cache.js exists"; exit 1; fi
echo "caught: cache.js is described but missing"
exit "$bad"
