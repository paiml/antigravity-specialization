#!/usr/bin/env bash
# Lesson 2.1.5: Debugging an agent mistake with logs. The mistake is seeded for real: the handler checks the trimmed title
# but stores the raw one. RUNS: red test, the log line and the stored value that show it, the fix, green test.
# BLOCKED when agy has no quota: the prompt that asks the agent to find the bug from the log.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
need_node || exit 1
new_workdir
copy_ms ch2-done "$WORK/app"
cd "$WORK/app" || exit 1
say "seed the mistake (the diff is shown)"
seed_bug_title "$WORK/app"
diff -u server.js.orig server.js | sed 's/^/  /'
say "RED: the tests notice"
node --test --test-force-exit test/api.test.js 2>&1 | grep -E '^# (tests|pass|fail)' | sed 's/^/  /'
if node --test --test-force-exit test/api.test.js >/dev/null 2>&1; then echo "FAIL the seeded bug was not caught"; exit 1; fi
say "reproduce it by hand and read the log"
start_app "$WORK/app" demo-token || exit 1
curl -sS -X POST "$APP_URL/api/tasks" -H 'Authorization: Bearer demo-token' -H 'content-type: application/json' -d '{"title":"  padded  "}'
echo
echo "log line:"
grep '"POST"' "$APP_LOG" | tail -n 1 | sed 's/^/  /'
stop_app
agy_step "$here/prompts/find-bug.md" plan "$WORK/app"
say "fix: restore the original line"
fix_bug server.js
say "GREEN"
node --test --test-force-exit test/api.test.js 2>&1 | grep -E '^# (tests|pass|fail)' | sed 's/^/  /'
node --test --test-force-exit test/api.test.js >/dev/null 2>&1 || { echo "FAIL not green after the fix"; exit 1; }
echo "green"
