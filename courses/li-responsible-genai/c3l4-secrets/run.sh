#!/usr/bin/env bash
# Lesson 3.4: keep secrets out of prompts and logs. Redact before the model sees it, then prove nothing leaked.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
log="$here/data/app.log"
pattern='(sk|pk)-[A-Za-z0-9]{12,}|AKIA[0-9A-Z]{16}|Bearer [A-Za-z0-9._-]{12,}|[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
echo "=== raw log (fake secrets, made up for this demo; never printed to the screen)"
echo "$(grep -Ec "$pattern" "$log") of $(wc -l <"$log") lines hold a secret-shaped value"
echo
echo "=== redacted copy"
${REDACT_CMD:-redact} <"$log" | tee "$here/app.redacted.log"
echo
echo "=== leak check on the redacted copy"
if grep -Eq "$pattern" "$here/app.redacted.log"; then
  echo "LEAK FOUND"
  exit 1
fi
echo "no secret pattern left"
if [ -z "${DEMO_NO_MODEL:-}" ] && need_server 2>/dev/null; then
  echo
  echo "=== only the redacted text goes to the model"
  ask "List the distinct problems in this log in one sentence." "$(cat "$here/app.redacted.log")" 80
fi
