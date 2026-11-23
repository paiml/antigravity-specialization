#!/usr/bin/env bash
# Lesson 2.1.3: Authentication basics and secrets handling. RUNS: curl 401 without a token, 401 with a wrong one, 201 with the right one,
# reads stay open, production refuses to start without a token, and the token never reaches the log.
# BLOCKED when agy has no quota: the review prompt.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
need_node || exit 1
new_workdir
copy_ms ch2-done "$WORK/app"
start_app "$WORK/app" demo-token || exit 1
json='content-type: application/json'
say "writes need the token"
expect_code "POST without a token" 401 -X POST "$APP_URL/api/tasks" -H "$json" -d '{"title":"a"}' || exit 1
expect_code "POST with a wrong token" 401 -X POST "$APP_URL/api/tasks" -H "$json" -H 'Authorization: Bearer nope' -d '{"title":"a"}' || exit 1
expect_code "POST with the right token" 201 -X POST "$APP_URL/api/tasks" -H "$json" -H 'Authorization: Bearer demo-token' -d '{"title":"a"}' || exit 1
cat "$WORK/body.json"
echo
say "reads are open"
expect_code "GET without a token" 200 "$APP_URL/api/tasks" || exit 1
say "production without a token must refuse to start"
(cd "$WORK/app" && NODE_ENV=production PORT=1 DB_PATH="$WORK/p.db" node main.js 2>&1 | sed 's/^/  /')
(cd "$WORK/app" && NODE_ENV=production PORT=1 DB_PATH="$WORK/p.db" node main.js >/dev/null 2>&1)
rc=$?
echo "exit code: $rc"
if [ "$rc" -ne 1 ]; then echo "FAIL expected exit 1"; exit 1; fi
say "the token must never be in the log"
if grep -q 'demo-token' "$APP_LOG"; then echo "FAIL the token is in the log"; exit 1; fi
echo "ok    no token in $(wc -l <"$APP_LOG") log lines"
agy_step "$here/prompts/review-auth.md" plan "$WORK/app"
