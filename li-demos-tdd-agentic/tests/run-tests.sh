#!/usr/bin/env bash
# Offline tests: no agy, no network, no login. tests/fake-agy stands in for agy.
set -uo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
. "$root/lib/common.sh"
pass=0
fail=0
ok() { pass=$((pass + 1)); echo "ok    $1"; }
no() { fail=$((fail + 1)); echo "FAIL  $1"; }
expect_eq() { if [ "$2" = "$3" ]; then ok "$1"; else no "$1 (got '$2', want '$3')"; fi; }
expect_rc() { # name want_rc cmd...
  local name="$1" want="$2"
  shift 2
  "$@" >/dev/null 2>&1
  local rc=$?
  if [ "$rc" -eq "$want" ]; then ok "$name"; else no "$name (rc $rc, want $want)"; fi
}
status_of() { grep '^LESSON-STATUS:' | tail -n 1 | cut -d' ' -f2; }
fake="$root/tests/fake-agy"

# the project stages behave as taught
w=$(new_work t)
for pair in "stub 1" "green 0" "n-red 1" "n-green 0" "n-refactor 0" "wrong 1" "cheat 0" "spec-only 1" "tests-written 1"; do
  set -- $pair
  stage_into "$w" "$1"
  expect_rc "stage $1 tests exit $2" "$2" run_tests "$w"
done
for pair in "stub 1" "green 0" "n-green 0" "narrow 1" "wrong 1"; do
  set -- $pair
  stage_into "$w" "$1"
  expect_rc "stage $1 properties exit $2" "$2" bash "$w/tests/property.sh"
done
stage_into "$w" n-green
expect_eq "slugify: lowercase and separators" "$("$w/src/slugify.sh" 'Hello, World!')" "hello-world"
expect_eq "slugify: -n cut removes trailing dash" "$("$w/src/slugify.sh" -n 6 'Hello World')" "hello"
stage_into "$w" n-refactor
expect_eq "refactored slugify gives the same answer" "$("$w/src/slugify.sh" -n 6 'Hello World')" "hello"

# verify.sh
g=$(new_work v)
stage_into "$g" n-red
expect_rc "verify red: n-red over green src" 0 "$root/scripts/verify.sh" "$g" red green
expect_rc "verify red fails when src was changed" 1 "$root/scripts/verify.sh" "$g" red n-green
expect_rc "verify green rejects red tests" 1 "$root/scripts/verify.sh" "$g" green n-red
stage_into "$g" n-green
expect_rc "verify green passes n-green" 0 "$root/scripts/verify.sh" "$g" green n-red
stage_into "$g" wrong
expect_rc "verify green rejects a wrong implementation" 1 "$root/scripts/verify.sh" "$g" green n-red
stage_into "$g" cheat
expect_rc "verify green rejects edited tests" 1 "$root/scripts/verify.sh" "$g" green stub
stage_into "$g" n-red
expect_rc "verify red fails when tests are green" 1 "$root/scripts/verify.sh" "$g" red n-green
stage_into "$g" n-red
expect_rc "verify spec passes with tagged tests" 0 "$root/scripts/verify.sh" "$g" spec green
expect_rc "verify spec fails when src differs" 1 "$root/scripts/verify.sh" "$g" spec n-green
stage_into "$g" spec-only
expect_rc "verify spec fails without tags" 1 "$root/scripts/verify.sh" "$g" spec stub
expect_rc "verify rejects an unknown mode" 2 "$root/scripts/verify.sh" "$g" bogus stub

# spec-lint: a rule without an example is reported
s=$(new_work s)
stage_into "$s" n-red
printf -- '- R1 Lowercase.\n' >"$s/spec/slugify.md"
expect_rc "spec-lint flags a rule with no example" 1 "$root/scripts/spec-lint.sh" "$s"

# plan-check
expect_rc "plan-check accepts a test-first plan" 0 "$root/scripts/plan-check.sh" "$root/fixtures/plan-sample.md"
expect_rc "plan-check rejects a plan with a path outside" 1 "$root/scripts/plan-check.sh" "$root/fixtures/plan-bad.md"
printf '1. Edit src/slugify.sh\n' >"$s/p.md"
expect_rc "plan-check rejects a plan with no test step" 1 "$root/scripts/plan-check.sh" "$s/p.md"

# review-diff
a=$(new_work a)
b=$(new_work b)
stage_into "$a" n-red
stage_into "$b" n-green
expect_rc "review-diff passes a source-only change (impl task)" 0 "$root/scripts/review-diff.sh" "$a" "$b"
expect_rc "review-diff flags a source change in a test-writing task" 1 "$root/scripts/review-diff.sh" "$a" "$b" tests
stage_into "$b" n-red
printf '# extra\n' >>"$b/tests/cases.txt"
expect_rc "review-diff passes a test-only change (test-writing task)" 0 "$root/scripts/review-diff.sh" "$a" "$b" tests
expect_rc "review-diff flags a test change in an implementation task" 1 "$root/scripts/review-diff.sh" "$a" "$b"
stage_into "$a" stub
stage_into "$b" cheat
expect_rc "review-diff flags the cheat stage" 1 "$root/scripts/review-diff.sh" "$a" "$b"

# contract-test
c=$(new_work c)
stage_into "$c" n-green
expect_rc "contract cases pass on n-green" 0 "$root/scripts/contract-test.sh" "$c" "$root/contracts/slugify-cases.yaml"
stage_into "$c" wrong
expect_rc "contract cases fail on the wrong implementation" 1 "$root/scripts/contract-test.sh" "$c" "$root/contracts/slugify-cases.yaml"

# mutation: the full suite kills every mutant, the weak suite does not
expect_rc "mutation: full suite kills all" 0 "$root/scripts/mutate.sh" n-green "$root/stages/n-green/tests/cases.txt"
expect_rc "mutation: weak suite leaves survivors" 1 "$root/scripts/mutate.sh" n-green "$root/stages/green/tests/cases.txt"
expect_rc "mutation: a mutation that does not apply is an error" 2 "$root/scripts/mutate.sh" green "$root/stages/green/tests/cases.txt"

# agy_pin and agy_step
expect_rc "agy_pin accepts the pinned version" 0 env AGY_BIN="$fake" bash -c ". '$root/lib/common.sh'; agy_pin"
expect_rc "agy_pin rejects another version" 1 env AGY_BIN="$fake" FAKE_AGY_MODE=wrong-version bash -c ". '$root/lib/common.sh'; agy_pin"

# every lesson, with the agent solving
export AGY_BIN="$fake"
for dir in "$root"/c*/run.sh; do
  name=$(basename "$(dirname "$dir")")
  case "$name" in
    c1l3-*) stage=tests-written ;;
    c2l1-*) stage=n-red ;;
    c2l2-* | c4l3-*) stage=n-green ;;
    c2l3-*) stage=n-refactor ;;
    c3l5-*) stage=n-green ;;
    *) stage=n-green ;;
  esac
  out=$(FAKE_AGY_MODE=solve FAKE_AGY_STAGE=$stage "$dir" 2>&1)
  rc=$?
  want=RUNS
  [ "$name" = c1l4-read-the-plan ] && want=RUNS
  expect_eq "lesson $name exits 0 (agent solving)" "$rc" "0"
  expect_eq "lesson $name status (agent solving)" "$(echo "$out" | status_of)" "$want"
done

# every lesson, with the agent blocked by quota: the reference checks still run and the status says BLOCKED
for dir in "$root"/c*/run.sh; do
  name=$(basename "$(dirname "$dir")")
  out=$(FAKE_AGY_MODE=quota "$dir" 2>&1)
  rc=$?
  st=$(echo "$out" | status_of)
  expect_eq "lesson $name exits 0 (agent blocked)" "$rc" "0"
  case "$name" in
    c1l3-* | c2l1-* | c2l2-* | c2l3-* | c3l5-* | c4l3-*) expect_eq "lesson $name is BLOCKED-quota" "$st" "BLOCKED-quota" ;;
    c1l4-*) expect_eq "lesson $name is SCRIPTED-NOT-RUN" "$st" "SCRIPTED-NOT-RUN" ;;
    *) expect_eq "lesson $name is RUNS without the agent" "$st" "RUNS" ;;
  esac
done

# auth and failure modes, and an agent that does the wrong thing
out=$(AGY_BIN="$fake" FAKE_AGY_MODE=auth "$root/c2l2-make-it-pass/run.sh" 2>&1)
expect_eq "auth failure is BLOCKED-auth" "$(echo "$out" | status_of)" "BLOCKED-auth"
out=$(AGY_BIN="$fake" FAKE_AGY_MODE=fail "$root/c2l2-make-it-pass/run.sh" 2>&1)
expect_eq "agent crash is FAILED" "$(echo "$out" | status_of)" "FAILED"
expect_rc "agent crash exits non-zero" 1 env AGY_BIN="$fake" FAKE_AGY_MODE=fail "$root/c2l2-make-it-pass/run.sh"
out=$(AGY_BIN="$fake" FAKE_AGY_MODE=solve FAKE_AGY_STAGE=cheat "$root/c2l2-make-it-pass/run.sh" 2>&1)
expect_eq "agent that edits tests is FAILED" "$(echo "$out" | status_of)" "FAILED"
out=$(AGY_BIN="$fake" FAKE_AGY_MODE=fail "$root/c1l4-read-the-plan/run.sh" 2>&1)
expect_eq "plan lesson: agent crash is FAILED" "$(echo "$out" | status_of)" "FAILED"
out=$(AGY_BIN="$fake" FAKE_AGY_MODE=fail "$root/c3l5-fan-out/run.sh" 2>&1)
expect_eq "fan-out: agent crash is FAILED" "$(echo "$out" | status_of)" "FAILED"
out=$(AGY_BIN="$fake" FAKE_AGY_MODE=solve FAKE_AGY_STAGE=wrong "$root/c3l5-fan-out/run.sh" 2>&1)
expect_eq "fan-out: no passing candidate is FAILED" "$(echo "$out" | status_of)" "FAILED"
out=$(AGY_BIN="$fake" FAKE_AGY_MODE=wrong-version "$root/c1l2-setup/run.sh" 2>&1)
expect_eq "setup: version mismatch is FAILED" "$(echo "$out" | status_of)" "FAILED"

# capture.sh writes a capture file with an exit code line
mkdir -p "$root/.run/cap"
expect_rc "capture.sh runs a lesson" 0 env CAPTURE_DIR="$root/.run/cap" AGY_BIN="$fake" "$root/scripts/capture.sh" c1l0-why-agents-need-tests
if grep -q '^# exit code: 0' "$root/.run/cap/c1l0-why-agents-need-tests.out"; then ok "capture file records the exit code"; else no "capture file records the exit code"; fi

echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
