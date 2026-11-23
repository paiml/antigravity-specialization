#!/usr/bin/env bash
# Lesson 1.1.1: Plan the app as a spec before any code.
# RUNS: the spec lint on the chapter 1 SPEC.md, and the same lint going red on a broken copy.
# BLOCKED when agy has no quota: the agent drafts the spec from prompts/draft-spec.md.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
new_workdir
copy_ms ch1-done "$WORK/app"

# spec_check FILE: the sections every spec needs, and numbered requirements that name a behaviour.
spec_check() {
  local f="$1" h miss=0 reqs
  for h in "Goal" "Users and scope" "Requirements" "Acceptance" "Non-goals"; do
    if grep -q "^## $h\$" "$f"; then echo "ok    section: $h"; else echo "FAIL  missing section: $h"; miss=1; fi
  done
  reqs=$(grep -cE '^[0-9]+\. ' "$f")
  echo "numbered requirements: $reqs"
  if [ "$reqs" -lt 5 ]; then echo "FAIL  fewer than 5 requirements"; miss=1; fi
  return "$miss"
}

agy_step "$here/prompts/draft-spec.md" plan "$WORK/app"
say "spec lint on the committed spec"
spec_check "$WORK/app/SPEC.md" || exit 1
say "the same lint on a spec with its Acceptance section removed (must go red)"
sed '/^## Acceptance/,/^## Non-goals/{/^## Non-goals/!d}' "$WORK/app/SPEC.md" >"$WORK/broken.md"
if spec_check "$WORK/broken.md"; then
  echo "FAIL the lint passed a broken spec"
  exit 1
fi
echo "lint went red on the broken spec, as it must"
