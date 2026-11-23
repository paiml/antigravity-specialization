#!/usr/bin/env bash
# Lesson 3.1.1: A static page that talks to the API. RUNS: the page files are served with the right types, the board logic tests,
# and the page script driven against the real server through a fake DOM (e2e test). The browser view is SCRIPTED:
# run with HOLD=1 and open the printed address. BLOCKED when agy has no quota: the agent that writes the page.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
need_node || exit 1
new_workdir
copy_ms ch3-done "$WORK/app"
agy_step "$here/prompts/build-page.md" accept-edits "$WORK/app"
start_app "$WORK/app" demo-token || exit 1
say "the page files and their content types"
for p in / /board.js /app.js /style.css; do
  curl -sS -o /dev/null -w "  %{http_code} %{content_type}  $p\n" "$APP_URL$p"
done
say "the page script uses textContent, not innerHTML"
if grep -q 'innerHTML' "$WORK/app/public/app.js"; then echo "FAIL innerHTML found"; exit 1; fi
echo "ok    no innerHTML in public/app.js"
say "board logic tests and the page-against-real-server test"
(cd "$WORK/app" && node --test --test-force-exit test/board.test.js test/e2e.test.js 2>&1 | grep -E '^# (tests|pass|fail)' | sed 's/^/  /')
(cd "$WORK/app" && node --test --test-force-exit test/board.test.js test/e2e.test.js >/dev/null 2>&1) || { echo "FAIL tests"; exit 1; }
say "put three tasks on the board through the API"
for t in "write the spec" "build the API" "ship it"; do
  curl -sS -o /dev/null -X POST "$APP_URL/api/tasks" -H 'Authorization: Bearer demo-token' -H 'content-type: application/json' -d "{\"title\":\"$t\"}"
done
curl -sS "$APP_URL/api/tasks" | node -e "let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{for(const t of JSON.parse(s))console.log('  '+t.id+' '+t.status+' '+t.title)})"
say "BROWSER STEP (scripted, not run): open $APP_URL and type the token demo-token"
hold_open
