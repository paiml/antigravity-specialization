#!/usr/bin/env bash
# Lesson 2.1.6: Backend checkpoint. RUNS: node --test --test-force-exit and the whole API walked with curl (smoke.sh) on a free port.
# No agent step in this lesson.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
need_node || exit 1
new_workdir
copy_ms ch2-done "$WORK/app"
cd "$WORK/app" || exit 1
say "unit and API tests"
node --test --test-force-exit 2>&1 | grep -E '^# (tests|pass|fail)' | sed 's/^/  /'
node --test --test-force-exit >/dev/null 2>&1 || { echo "FAIL tests"; exit 1; }
say "the whole API from curl"
PORT=$(free_port) scripts/smoke.sh || exit 1
say "tag the milestone in a scratch repository"
g() { git -c core.hooksPath=/dev/null -c user.name=demo -c user.email=demo "$@"; }
g init -q -b main
g add -A
g commit -q -m "ch2: migrations, API, auth, docs"
g tag ch2-done
g log --oneline --decorate | sed 's/^/  /'
