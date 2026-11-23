#!/usr/bin/env bash
# Lesson 1.1.5: Scaffold the repo and make the first commit. RUNS: tree, make ci on the scaffold, first commit and tag
# in a scratch repository (nothing is pushed). BLOCKED when agy has no quota: the agent scaffold prompt.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
need_node || exit 1
new_workdir
copy_ms ch1-done "$WORK/app"
agy_step "$here/prompts/scaffold.md" accept-edits "$WORK/app"
cd "$WORK/app" || exit 1
say "tree"
find . -type f | sort | sed 's#^\./#  #'
say "make ci (shellcheck, htmlhint, node --test)"
make ci 2>&1 | grep -E 'lint|^# (tests|pass|fail)' | sed 's/^/  /'
if ! make ci >/dev/null 2>&1; then echo "FAIL make ci"; exit 1; fi
say "first commit in a scratch repository"
g() { git -c core.hooksPath=/dev/null -c user.name=demo -c user.email=demo@example.com "$@"; }
g init -q -b main
g add -A
g commit -q -m "ch1: spec, context, decisions, scaffold"
g tag ch1-done
g log --oneline --decorate | sed 's/^/  /'
