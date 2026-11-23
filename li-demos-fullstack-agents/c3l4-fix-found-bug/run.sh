#!/usr/bin/env bash
# Lesson 3.1.4: Fixing what the browser agent found. RUNS: the seeded bug (same as 3.1.3) red in the tests, the fix, green, the full
# page-against-server test, and `make ci`. The browser confirmation is SCRIPTED (HOLD=1). BLOCKED when agy has no quota: the fix prompt.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
need_node || exit 1
new_workdir
copy_ms ch3-done "$WORK/app"
cd "$WORK/app" || exit 1
seed_bug_board "$WORK/app"
say "RED: the board test names the failure"
node --test --test-force-exit test/board.test.js 2>&1 | grep -E '^not ok|^# (tests|pass|fail)' | sed 's/^/  /'
if node --test --test-force-exit test/board.test.js >/dev/null 2>&1; then echo "FAIL the seeded bug was not caught"; exit 1; fi
agy_step "$here/prompts/fix-column.md" accept-edits "$WORK/app"
say "fix: restore the original line (the diff is shown)"
fix_bug public/board.js
say "GREEN: the whole suite, including the page driven against the real server"
node --test --test-force-exit 2>&1 | grep -E '^# (tests|pass|fail)' | sed 's/^/  /'
node --test --test-force-exit >/dev/null 2>&1 || { echo "FAIL not green after the fix"; exit 1; }
say "make ci"
make ci 2>&1 | tail -n 3 | sed 's/^/  /'
make ci >/dev/null 2>&1 || { echo "FAIL make ci"; exit 1; }
start_app "$WORK/app" demo-token || exit 1
say "BROWSER STEP (scripted, not run): reload $APP_URL, add a task, move it to Done, and read the Done count"
hold_open
