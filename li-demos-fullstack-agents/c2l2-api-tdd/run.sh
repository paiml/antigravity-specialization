#!/usr/bin/env bash
# Lesson 2.1.2: API endpoints driven by tests. RUNS: the API tests red against the chapter 1 server, then green against the real one.
# BLOCKED when agy has no quota: the prompt that asks the agent to make the red tests pass.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
need_node || exit 1
new_workdir
copy_ms ch2-done "$WORK/app"
cd "$WORK/app" || exit 1
cp server.js "$WORK/server.real.js"
cp "$DEMO_ROOT/milestones/ch1-done/server.js" server.js
say "RED: the API tests against a server that only knows /healthz"
node --test --test-force-exit test/api.test.js 2>&1 | grep -E '^# (tests|pass|fail)' | sed 's/^/  /'
if node --test --test-force-exit test/api.test.js >/dev/null 2>&1; then echo "FAIL the tests passed against the stub"; exit 1; fi
echo "red, as it must be"
agy_step "$here/prompts/make-green.md" accept-edits "$WORK/app"
cp "$WORK/server.real.js" server.js
say "GREEN: the real server.js back in place"
node --test --test-force-exit test/api.test.js 2>&1 | grep -E '^# (tests|pass|fail)' | sed 's/^/  /'
node --test --test-force-exit test/api.test.js >/dev/null 2>&1 || { echo "FAIL the tests are not green"; exit 1; }
echo "green"
