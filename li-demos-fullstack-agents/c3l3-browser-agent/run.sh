#!/usr/bin/env bash
# Lesson 3.1.3: Using the browser subagent to click through the app. The bug is seeded for real: the column grouping matches on a
# two letter prefix, so a "done" task is filed under "doing". RUNS: the seeded bug, the data the page gets from the API, and what the
# grouping does with it. SCRIPTED: the browser agent itself (no CLI flag drives it; it is started by prompt) and the browser view.
# BLOCKED when agy has no quota. [VERIFY-ON-RECORD] how the browser subagent appears on screen.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
need_node || exit 1
new_workdir
copy_ms ch3-done "$WORK/app"
cd "$WORK/app" || exit 1
say "seed the bug (the diff is shown)"
seed_bug_board "$WORK/app"
diff -u public/board.js.orig public/board.js | sed 's/^/  /'
start_app "$WORK/app" demo-token || exit 1
say "two tasks: one doing, one done"
curl -sS -o /dev/null -X POST "$APP_URL/api/tasks" -H 'Authorization: Bearer demo-token' -H 'content-type: application/json' -d '{"title":"in progress"}'
curl -sS -o /dev/null -X POST "$APP_URL/api/tasks" -H 'Authorization: Bearer demo-token' -H 'content-type: application/json' -d '{"title":"finished"}'
curl -sS -o /dev/null -X PATCH "$APP_URL/api/tasks/1" -H 'Authorization: Bearer demo-token' -H 'content-type: application/json' -d '{"status":"doing"}'
curl -sS -o /dev/null -X PATCH "$APP_URL/api/tasks/2" -H 'Authorization: Bearer demo-token' -H 'content-type: application/json' -d '{"status":"done"}'
say "what the API says (correct)"
curl -sS "$APP_URL/api/tasks" | node -e "let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{for(const t of JSON.parse(s))console.log('  '+t.title+' -> '+t.status)})"
say "what the page would draw from that data (the seeded grouping)"
curl -sS "$APP_URL/api/tasks" | node -e "
const B=require('./public/board.js');let s='';
process.stdin.on('data',d=>s+=d).on('end',()=>{const g=B.groupByStatus(JSON.parse(s));
for(const k of B.STATUSES)console.log('  '+k+': '+g[k].map(t=>t.title).join(', '))})"
say "the existing board test sees it too"
node --test --test-force-exit test/board.test.js 2>&1 | grep -E '^# (tests|pass|fail)' | sed 's/^/  /'
if node --test --test-force-exit test/board.test.js >/dev/null 2>&1; then echo "FAIL the seeded bug was not caught"; exit 1; fi
agy_step "$here/prompts/browser-agent.md" auto "$WORK/app"
say "BROWSER STEP (scripted, not run): the agent opens $APP_URL and reports what the Done column shows"
hold_open
