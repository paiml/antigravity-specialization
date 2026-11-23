#!/usr/bin/env bash
# plan-check.sh PLAN.md: read an agent plan before it codes. Test steps come first; nothing outside the project.
set -uo pipefail
plan="$1"
t=$(grep -nEi '^[0-9]+\..*test' "$plan" | head -n 1 | cut -d: -f1)
s=$(grep -nE '^[0-9]+\..*src/' "$plan" | head -n 1 | cut -d: -f1)
bad=0
if [ -z "$t" ] || [ -z "$s" ] || [ "$t" -ge "$s" ]; then
  echo "PLAN PROBLEM: no test step before the first source step"
  bad=1
fi
if grep -Eq '(\.\./|/etc/|~/)' "$plan"; then
  echo "PLAN PROBLEM: touches a path outside the project"
  bad=1
fi
echo "plan-check: test step line ${t:-none}, source step line ${s:-none}, problems $bad"
[ "$bad" -eq 0 ]
