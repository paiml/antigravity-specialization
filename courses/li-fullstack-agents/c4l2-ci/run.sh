#!/usr/bin/env bash
# Lesson 4.1.2: CI pipeline with tests and lint. RUNS: the workflow file is checked for what it must contain, `make ci` is run exactly as
# the workflow runs it, and a failing test is shown turning it red. SCRIPTED: the pull request and the required check on the host
# (a repository setting, not code). BLOCKED when agy has no quota: the workflow prompt.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
need_node || exit 1
new_workdir
copy_ms v1.0.0 "$WORK/app"
cd "$WORK/app" || exit 1
wf=".github/workflows/ci.yml"
say "the workflow"
cat "$wf"
agy_step "$here/prompts/workflow.md" accept-edits "$WORK/app"
say "what it must contain"
bad=0
for pat in 'pull_request' 'branches: \[main\]' 'node-version-file: .nvmrc' 'make ci' 'make smoke' 'timeout-minutes'; do
  if grep -q "$pat" "$wf"; then echo "ok    $pat"; else echo "FAIL  missing: $pat"; bad=1; fi
done
if grep -qE 'continue-on-error|\|\| true' "$wf"; then echo "FAIL  the workflow can hide a failure"; bad=1; else echo "ok    no continue-on-error, no '|| true'"; fi
if [ "$bad" -ne 0 ]; then exit 1; fi
say "run what the workflow runs"
make ci 2>&1 | tail -n 4 | sed 's/^/  /'
make ci >/dev/null 2>&1 || { echo "FAIL make ci"; exit 1; }
PORT=$(free_port) make smoke 2>&1 | tail -n 1 | sed 's/^/  /'
say "a failing test must turn it red"
printf "require('node:test')('ci must fail on this', () => { throw new Error('deliberate'); });\n" >test/zz-fail.test.js
if make ci >/dev/null 2>&1; then echo "FAIL make ci passed with a failing test"; exit 1; fi
echo "make ci went red, as it must"
say "BRANCH PROTECTION (scripted, not run): make the job named gate a required check on main"
