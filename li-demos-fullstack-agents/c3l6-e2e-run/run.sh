#!/usr/bin/env bash
# Lesson 3.1.6: End-to-end run of the whole app. RUNS: the end-to-end test (a real server, the real page script driven through a fake
# DOM: add, move both ways, delete, validation, wrong token, 404 message), then every control exercised over HTTP on a scratch server
# with the result read back from the database. NOT RUN: a real browser. The agent-driven browser pass is SCRIPTED (HOLD=1).
# BLOCKED when agy has no quota: the agent that drives every control.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
need_node || exit 1
new_workdir
copy_ms ch3-done "$WORK/app"
cd "$WORK/app" || exit 1
say "the end-to-end test"
node --test --test-force-exit test/e2e.test.js 2>&1 | grep -E '^# (tests|pass|fail)' | sed 's/^/  /'
node --test --test-force-exit test/e2e.test.js >/dev/null 2>&1 || { echo "FAIL e2e"; exit 1; }
start_app "$WORK/app" demo-token || exit 1
json='content-type: application/json'
auth='Authorization: Bearer demo-token'
say "every control, over HTTP"
expect_code "page loads" 200 "$APP_URL/" || exit 1
expect_code "add task (Add button)" 201 -X POST "$APP_URL/api/tasks" -H "$json" -H "$auth" -d '{"title":"e2e card"}' || exit 1
expect_code "move right to doing" 200 -X PATCH "$APP_URL/api/tasks/1" -H "$json" -H "$auth" -d '{"status":"doing"}' || exit 1
expect_code "move right to done" 200 -X PATCH "$APP_URL/api/tasks/1" -H "$json" -H "$auth" -d '{"status":"done"}' || exit 1
expect_code "move left to doing" 200 -X PATCH "$APP_URL/api/tasks/1" -H "$json" -H "$auth" -d '{"status":"doing"}' || exit 1
expect_code "empty title refused" 400 -X POST "$APP_URL/api/tasks" -H "$json" -H "$auth" -d '{"title":""}' || exit 1
expect_code "wrong token refused" 401 -X DELETE "$APP_URL/api/tasks/1" -H 'Authorization: Bearer nope' || exit 1
say "read back from the database file (not from the API)"
row=$(sql "$WORK/app/data/taskpad.db" "select title || ' | ' || status from tasks where id=1")
echo "  $row"
if [ "$row" != "e2e card | doing" ]; then echo "FAIL stored row is wrong"; exit 1; fi
expect_code "delete (Delete button)" 204 -X DELETE "$APP_URL/api/tasks/1" -H "$auth" || exit 1
n=$(sql "$WORK/app/data/taskpad.db" "select count(*) from tasks")
echo "  rows left: $n"
if [ "$n" -ne 0 ]; then echo "FAIL the row is still there"; exit 1; fi
agy_step "$here/prompts/drive-every-control.md" auto "$WORK/app"
say "BROWSER STEP (scripted, not run): the agent drives every control at $APP_URL; a probar run is the missing receipt"
hold_open
