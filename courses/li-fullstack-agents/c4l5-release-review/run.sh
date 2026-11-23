#!/usr/bin/env bash
# Lesson 4.1.5: Release checklist and final review. RUNS: a clean clone of the finished app, then the checklist items that a machine
# can check: make ci, make smoke, production refusing to start without a token, no secrets in the tree, docs listing every route.
# SCRIPTED: the live page check on a deployed host. BLOCKED when agy has no quota: the risk review prompt.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
need_node || exit 1
new_workdir
g() { git -c core.hooksPath=/dev/null -c user.name=demo -c user.email=demo@example.com "$@"; }
copy_ms v1.0.0 "$WORK/src"
(cd "$WORK/src" && g init -q -b main && g add -A && g commit -q -m "release candidate")
say "a clean clone, not the working copy"
g clone -q "$WORK/src" "$WORK/clone"
cd "$WORK/clone" || exit 1
say "checklist"
bad=0
if make --no-print-directory ci >/dev/null 2>&1; then echo "ok    make ci is green"; else echo "FAIL  make ci"; bad=1; fi
if PORT=$(free_port) make --no-print-directory smoke 2>&1 | tail -n 1 | grep -q 'smoke OK'; then echo "ok    make smoke prints smoke OK"; else echo "FAIL  make smoke"; bad=1; fi
msg=$(NODE_ENV=production DB_PATH="$WORK/c.db" node main.js 2>&1)
rc=$?
if [ "$rc" -eq 1 ]; then echo "ok    production without a token exits 1: $msg"; else echo "FAIL  production start (exit $rc)"; bad=1; fi
hits=$(grep -rn 'Bearer ' . --exclude-dir=.git --exclude-dir=test --exclude-dir=docs --exclude-dir=scripts --exclude-dir=testlib --exclude=SPEC.md --exclude=RELEASE-CHECKLIST.md | grep -v 'server.js\|app.js' | wc -l)
if [ "$hits" -eq 0 ]; then echo "ok    no bearer token outside code, tests and docs"; else echo "FAIL  $hits stray bearer strings"; bad=1; fi
missing=0
for r in /healthz /api/tasks /api/tasks/:id; do
  if ! grep -q "^## [A-Z]* $r\$" docs/API.md; then echo "FAIL  $r is not in docs/API.md"; missing=1; fi
done
if [ "$missing" -eq 0 ]; then echo "ok    docs/API.md lists every route"; else bad=1; fi
n=$(grep -c '^- \[ \]' RELEASE-CHECKLIST.md)
echo "checklist items in the file: $n"
if [ "$n" -lt 8 ]; then echo "FAIL  checklist too short"; bad=1; fi
agy_step "$here/prompts/risk-review.md" plan "$WORK/clone"
say "LIVE PAGE (scripted, not run): open the deployed address, add a task, reload, confirm it stays"
exit "$bad"
