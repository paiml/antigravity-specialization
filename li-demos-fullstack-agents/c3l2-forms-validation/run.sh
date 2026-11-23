#!/usr/bin/env bash
# Lesson 3.1.2: Forms and validation. RUNS: the page and the server agree on the title rule (same bounds, both reject, and the
# server never trusts the page), and the 401 message the page shows. The form in a browser is SCRIPTED (HOLD=1).
# BLOCKED when agy has no quota: the validation prompt.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
need_node || exit 1
new_workdir
copy_ms ch3-done "$WORK/app"
cd "$WORK/app" || exit 1
agy_step "$here/prompts/validation.md" accept-edits "$WORK/app"
start_app "$WORK/app" demo-token || exit 1
long=$(node -e "console.log('x'.repeat(121))")
say "the page's rule (public/board.js)"
node -e "const B=require('./public/board.js');for(const t of ['','   ','ok',process.argv[1]])console.log('  len '+String(t).length+' ->',JSON.stringify(B.validateTitle(t)).slice(0,70))" "$long" 2>&1 | sed 's/^/  /'
say "the server's rule, sent directly so the page cannot help it"
json='content-type: application/json'
auth='Authorization: Bearer demo-token'
expect_code "empty title" 400 -X POST "$APP_URL/api/tasks" -H "$json" -H "$auth" -d '{"title":""}' || exit 1
cat "$WORK/body.json"; echo
expect_code "spaces only" 400 -X POST "$APP_URL/api/tasks" -H "$json" -H "$auth" -d '{"title":"   "}' || exit 1
expect_code "121 characters" 400 -X POST "$APP_URL/api/tasks" -H "$json" -H "$auth" -d "{\"title\":\"$long\"}" || exit 1
expect_code "a number as the title" 400 -X POST "$APP_URL/api/tasks" -H "$json" -H "$auth" -d '{"title":5}' || exit 1
expect_code "120 characters is fine" 201 -X POST "$APP_URL/api/tasks" -H "$json" -H "$auth" -d "{\"title\":\"${long%x}\"}" || exit 1
say "the page and the server accept and refuse the same lengths"
bad=0
for n in 0 1 119 120 121 200; do
  page=$(node -e "const B=require('./public/board.js');console.log(B.validateTitle('x'.repeat(+process.argv[1])).error?'refuse':'accept')" "$n")
  title=$(node -e "console.log('x'.repeat(+process.argv[1]))" "$n")
  code=$(curl -sS -o /dev/null -w '%{http_code}' -X POST "$APP_URL/api/tasks" -H "$json" -H "$auth" -d "{\"title\":\"$title\"}")
  if [ "$code" = 201 ]; then srv=accept; else srv=refuse; fi
  if [ "$page" = "$srv" ]; then echo "ok    length $n: both $page"; else echo "FAIL  length $n: page $page, server $srv"; bad=1; fi
done
say "BROWSER STEP (scripted, not run): $APP_URL, submit an empty title, then a wrong token, and read the message"
hold_open
exit "$bad"
