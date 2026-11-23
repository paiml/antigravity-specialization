#!/usr/bin/env bash
# Offline tests. Every lesson script runs for real (a real Taskpad server on a free local port, real node:sqlite, real curl),
# with the agy CLI replaced by a stub so no quota and no login is needed. Each test can fail: the gate tests feed a bad
# input and require the gate to go red, and every seeded-bug lesson requires its own red step.
set -uo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
. "$root/lib/common.sh"
need_node || exit 1
work="$root/.run/test"
rm -rf "${work:?}"
mkdir -p "$work"
pass=0 fail=0
ok() { pass=$((pass + 1)); echo "ok    $1"; }
no() { fail=$((fail + 1)); echo "FAIL  $1"; }
expect_has() { case "$2" in *"$3"*) ok "$1" ;; *) no "$1 (missing '$3')" ;; esac; }
expect_rc() { # name want_rc cmd...
  local name="$1" want="$2"
  shift 2
  "$@" >/dev/null 2>&1
  local rc=$?
  if [ "$rc" -eq "$want" ]; then ok "$name"; else no "$name (rc $rc, want $want)"; fi
}
stub="$root/tests/bin/agy"

# every lesson: exit 0, no FAIL line, and the marker line that proves its main step ran
lesson() { # dir marker
  local out rc
  out=$(AGY_BIN="$stub" "$root/$1/run.sh" 2>&1 </dev/null)
  rc=$?
  if [ "$rc" -ne 0 ]; then
    no "$1 exits 0 (rc $rc)"
    echo "$out" | tail -n 8 | sed 's/^/        /'
    return
  fi
  if [ -z "${ALLOW_FAIL:-}" ]; then case "$out" in *"FAIL "*) no "$1 prints no FAIL line"; return ;; esac; fi
  expect_has "$1 ran ($2)" "$out" "$2"
}
lesson c1l0-what-we-build "BROWSER STEP"
ALLOW_FAIL=1 lesson c1l1-spec "lint went red on the broken spec"
lesson c1l2-context "caught: make deploy-all"
lesson c1l3-architecture-review "caught: cache.js"
lesson c1l4-stack-check "package.json has no dependencies"
lesson c1l5-scaffold-commit "first commit"
lesson c2l1-migrations "rows in schema_migrations: 2"
lesson c2l2-api-tdd "red, as it must be"
lesson c2l3-auth "no token in"
lesson c2l4-second-agent-docs "caught: PUT"
lesson c2l5-debug-with-logs "green"
lesson c2l6-backend-checkpoint "smoke OK"
lesson c3l1-static-page "BROWSER STEP"
lesson c3l2-forms-validation "both"
lesson c3l3-browser-agent "seed the bug"
lesson c3l4-fix-found-bug "GREEN: the whole suite"
lesson c3l5-a11y-mobile "BROWSER STEP"
lesson c3l6-e2e-run "BROWSER STEP"
lesson c4l2-ci "went red, as it must"
lesson c4l3-deploy "deploy OK"
lesson c4l4-monitor-rollback "refused, as it must"
lesson c4l5-release-review "checklist items"
lesson c4l6-conclusion "NEXT STEPS"
if docker info >/dev/null 2>&1; then
  lesson c4l1-container "the task is still there"
else
  echo "skip  c4l1-container (no docker daemon here)"
fi
out=$(DOCKER=/nonexistent/docker AGY_BIN="$stub" "$root/c4l1-container/run.sh" 2>&1 </dev/null)
expect_has "c4l1 prints DOCKER-BLOCKED without docker" "$out" "DOCKER-BLOCKED"

# agy_step: a quota failure prints a BLOCKED line and the lesson goes on; a remembered block is not retried
out=$(AGY_STUB_RC=1 AGY_BIN="$stub" "$root/c1l1-spec/run.sh" 2>&1 </dev/null)
expect_has "agy quota failure is reported as BLOCKED" "$out" "AGY-BLOCKED: exit 1: error: stub quota reached"
AGY_STATE="$work/agy-state" AGY_STUB_RC=1 AGY_BIN="$stub" "$root/c1l1-spec/run.sh" >/dev/null 2>&1 </dev/null
out=$(AGY_STATE="$work/agy-state" AGY_BIN="$stub" "$root/c1l1-spec/run.sh" 2>&1 </dev/null)
expect_has "a remembered block is not retried" "$out" "not retried in this session"
out=$(AGY_BIN="$stub" "$root/c1l1-spec/run.sh" 2>&1 </dev/null)
expect_has "agy reply is shown" "$out" "> stub agent reply"

# HOLD keeps the app up until Enter
out=$(echo | HOLD=1 AGY_BIN="$stub" "$root/c3l1-static-page/run.sh" 2>&1)
expect_has "HOLD waits for Enter" "$out" "(HOLD is set)"

# helpers
expect_rc "need_node fails when node is missing" 1 env -i PATH=/usr/bin:/bin HOME=/nonexistent bash -c ". '$root/lib/common.sh'; need_node"
expect_rc "start_app reports a server that will not start" 1 bash -c ". '$root/lib/common.sh'; need_node; new_workdir; copy_ms ch1-done \"\$WORK/a\"; echo 'process.exit(1)' >\"\$WORK/a/main.js\"; start_app \"\$WORK/a\" t"
expect_rc "expect_code fails on a wrong status" 1 bash -c ". '$root/lib/common.sh'; need_node; new_workdir; copy_ms ch1-done \"\$WORK/a\"; start_app \"\$WORK/a\" t; expect_code x 500 \"\$APP_URL/healthz\""

# gates
sp="$root/tests/bin:$PATH"
out=$(env PATH="$sp" "$root/scripts/gate-lint.sh")
expect_has "lint gate passes and counts files" "$out" "lint OK"
expect_rc "lint gate fails on a lint error" 1 env PATH="$sp" BASHRS_RC=1 "$root/scripts/gate-lint.sh"
expect_rc "lint gate fails on 0 files" 1 env PATH="$sp" LINT_FILES= "$root/scripts/gate-lint.sh"
expect_rc "nopython gate passes on this repo" 0 "$root/scripts/gate-nopython.sh"
expect_rc "nopython gate fails on 0 files" 1 env NOPY_FILES= "$root/scripts/gate-nopython.sh"
printf 'x = 1\n' >"$work/bad.py"
expect_rc "nopython gate fails on a .py file" 1 env NOPY_FILES="$work/bad.py" "$root/scripts/gate-nopython.sh"
printf "%s -c x\n" py"thon3" >"$work/call.sh"
expect_rc "nopython gate fails on an interpreter call" 1 env NOPY_FILES="$work/call.sh" "$root/scripts/gate-nopython.sh"

# leak gate: the fixtures are built from pieces so this file does not trip the scan itself
printf 'plain text\n' >"$work/leak-clean.txt"
printf '%s%s\n' "AKIA" "ABCDEFGHIJKLMNOP" >"$work/leak-key.txt"
printf '%s%s\n' "cd /mn" "t/data" >"$work/leak-path.txt"
expect_rc "leak gate passes a clean file" 0 env LEAK_FILES="$work/leak-clean.txt" "$root/scripts/gate-leaks.sh"
expect_rc "leak gate fails on a key shape" 1 env LEAK_FILES="$work/leak-key.txt" "$root/scripts/gate-leaks.sh"
expect_rc "leak gate fails on a local path" 1 env LEAK_FILES="$work/leak-path.txt" "$root/scripts/gate-leaks.sh"
expect_rc "leak gate fails on 0 files" 1 env LEAK_FILES= "$root/scripts/gate-leaks.sh"
printf 'theme = "%s-dark"\n' "rme""dia" >"$work/leak-theme.txt"
expect_rc "leak gate allows the scene theme name" 0 env LEAK_FILES="$work/leak-theme.txt" "$root/scripts/gate-leaks.sh"
printf 'theme = "%s-dark"\n%s%s\n' "rme""dia" "cd /mn" "t/data" >"$work/leak-theme2.txt"
expect_rc "leak gate still fails a path beside the theme" 1 env LEAK_FILES="$work/leak-theme2.txt" "$root/scripts/gate-leaks.sh"
expect_rc "leak gate passes this repo" 0 "$root/scripts/gate-leaks.sh"

# js and contract gates (the milestones' own tests and 100% node coverage run inside gate-js)
out=$("$root/scripts/gate-js.sh" 2>&1)
expect_has "js gate runs every milestone and covers 100%" "$out" "js OK"
mkdir -p "$work/nopv"
expect_has "contract gate says SKIPPED when pv is missing" "$(env PATH="$work/nopv:/usr/bin:/bin" /bin/bash "$root/scripts/gate-contract.sh" 2>&1)" "SKIPPED"
if command -v pv >/dev/null 2>&1; then
  expect_has "contract gate validates the contract" "$("$root/scripts/gate-contract.sh" 2>&1)" "contract OK"
fi


# replay shim: banner first, reply is the committed SPEC.md, unknown prompt and missing --print are refused
shim="$root/scripts/agy-replay.sh"
rp_out=$("$shim" --print="$(cat "$root/c1l1-spec/prompts/draft-spec.md")" --mode plan --print-timeout 300s 2>&1)
expect_has "replay prints the banner" "$(echo "$rp_out" | head -n 1)" "REPLAY: reference reply, NOT live agent output"
if [ "$(echo "$rp_out" | tail -n +2)" = "$(cat "$root/milestones/ch1-done/SPEC.md")" ]; then ok "replay reply is the committed SPEC.md"; else no "replay reply is the committed SPEC.md"; fi
expect_rc "replay refuses an unknown prompt" 2 "$shim" --print="no such prompt" --mode plan
expect_rc "replay refuses a missing prompt" 2 "$shim" --mode plan
expect_has "replay --version prints the pin" "$(AGY_PIN=9.9.9 "$shim" --version)" "9.9.9"
rp2_out=$("$shim" --print="$(cat "$root/c1l2-context/prompts/load-context.md")" --mode plan --print-timeout 300s 2>&1)
expect_has "replay c1l2 prints the banner" "$(echo "$rp2_out" | head -n 1)" "REPLAY: reference reply, NOT live agent output"
if [ "$(echo "$rp2_out" | tail -n +2)" = "$(cat "$root/milestones/ch1-done/CONTEXT.md")" ]; then ok "replay c1l2 reply is the committed CONTEXT.md"; else no "replay c1l2 reply is the committed CONTEXT.md"; fi
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
