#!/usr/bin/env bash
set -uo pipefail
. "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
# 1.4 Read the plan before it codes. MIXED: the Antigravity plan artifact is a UI view.
# SCRIPTED-NOT-RUN: the plan comes from an agent turn (blocked when quota is out); plan-check runs on sample plans.
d=$(new_work plan)
stage_into "$d" n-red
agy_step "$d" "$ROOT/prompts/plan-first.md"
banner "plan-check on a sample good plan (hand-written)"
"$ROOT/scripts/plan-check.sh" "$ROOT/fixtures/plan-sample.md" || LESSON_STATUS=FAILED
banner "plan-check on a sample bad plan (hand-written): must be rejected"
if "$ROOT/scripts/plan-check.sh" "$ROOT/fixtures/plan-bad.md"; then LESSON_STATUS=FAILED; fi
if [ "$AGY_STATUS" = RAN ]; then
  banner "plan-check on the agent's plan"
  cp "$d/.agy-out" "$d/plan.md"
  "$ROOT/scripts/plan-check.sh" "$d/plan.md" || LESSON_STATUS=FAILED
else
  [ "$LESSON_STATUS" = FAILED ] || LESSON_STATUS=SCRIPTED-NOT-RUN
fi
[ "$AGY_STATUS" = FAILED ] && LESSON_STATUS=FAILED
finish
