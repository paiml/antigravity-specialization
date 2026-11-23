#!/usr/bin/env bash
# Lesson 1.1.0: What we will build. Start the finished Taskpad and look at it from the outside.
# Terminal half RUNS. The browser half is SCRIPTED: open the printed address on record day.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
need_node || exit 1
new_workdir
copy_ms v1.0.0 "$WORK/app"
say "the finished repo"
(cd "$WORK/app" && ls)
say "start it on a scratch port with a throwaway token"
start_app "$WORK/app" demo-token || exit 1
say "health, then the empty board's API"
curl -fsS "$APP_URL/healthz"
echo
curl -fsS "$APP_URL/api/tasks"
echo
say "the page is plain HTML"
curl -fsS "$APP_URL/" | head -n 8
say "BROWSER STEP (scripted, not run): open $APP_URL in a browser and type the token demo-token"
