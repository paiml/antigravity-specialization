#!/usr/bin/env bash
# Shared helpers for the demos. Source this file; it sets no shell options.
ROOT="${ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
AGY_BIN="${AGY_BIN:-agy}"
AGY_PIN="${AGY_PIN:-1.5.10}"
LESSON_STATUS=RUNS
AGY_STATUS=NOT-RUN
export ROOT AGY_BIN AGY_PIN

banner() { printf '\n== %s ==\n' "$*"; }

# new_work NAME: a fresh scratch directory under .run (never reused, never deleted by the demos).
new_work() {
  mkdir -p "$ROOT/.run"
  local d
  d=$(mktemp -d "$ROOT/.run/work-$1-XXXXXX")
  printf '%s' "$d"
}

# stage_into DIR STAGE: the project template, then the files of one stage on top.
stage_into() {
  cp -R "$ROOT/project/." "$1/"
  cp -R "$ROOT/stages/$2/." "$1/"
}

# run_tests DIR: the project's own test command; returns its exit code.
run_tests() {
  (cd "$1" && bash tests/run.sh)
}

# agy_pin: the installed agy must be the version this course was recorded with.
agy_pin() {
  local v
  v=$("$AGY_BIN" --version 2>&1 | head -n 1)
  if [ "$v" = "$AGY_PIN" ]; then
    printf 'agy version %s (pinned %s): ok\n' "$v" "$AGY_PIN"
  else
    printf 'agy version %s (pinned %s): MISMATCH\n' "$v" "$AGY_PIN"
    return 1
  fi
}

# agy_step DIR PROMPTFILE: one non-interactive agent turn inside DIR.
# Sets AGY_STATUS to RAN, BLOCKED-quota, BLOCKED-auth or FAILED. No login is ever attempted.
agy_step() {
  local out="$1/.agy-out" rc
  banner "agent step: agy --mode accept-edits --print"
  (cd "$1" && timeout "${AGY_TIMEOUT:-900}" "$AGY_BIN" --mode accept-edits --add-dir "$1" --print="$(cat "$2")") >"$out" 2>&1
  rc=$?
  if grep -q 'RESOURCE_EXHAUSTED' "$out"; then
    AGY_STATUS=BLOCKED-quota
  elif grep -Eqi 'unauthenticated|not logged in|sign in|login required' "$out"; then
    AGY_STATUS=BLOCKED-auth
  elif [ "$rc" -ne 0 ]; then
    AGY_STATUS=FAILED
  else
    AGY_STATUS=RAN
  fi
  tail -n 4 "$out"
  printf 'AGENT-STEP: %s\n' "$AGY_STATUS"
  printf '%s' "$AGY_STATUS" >"$1/.agy-status"
}

# agent_lesson BASE_STAGE PROMPT MODE REFERENCE_STAGE PIN_STAGE
# Runs the agent on BASE_STAGE and verifies its work. When the agent cannot run, the same check is
# run on a hand-written REFERENCE solution so the check itself is still shown (labelled as such).
agent_lesson() {
  local d r
  d=$(new_work agent)
  stage_into "$d" "$1"
  agy_step "$d" "$ROOT/prompts/$2"
  case "$AGY_STATUS" in
    RAN)
      banner "verify the agent's work"
      if "$ROOT/scripts/verify.sh" "$d" "$3" "$5"; then LESSON_STATUS=RUNS; else LESSON_STATUS=FAILED; fi
      ;;
    FAILED)
      LESSON_STATUS=FAILED
      ;;
    *)
      LESSON_STATUS="$AGY_STATUS"
      banner "reference check (hand-written solution, NOT agent output)"
      r=$(new_work ref)
      stage_into "$r" "$4"
      "$ROOT/scripts/verify.sh" "$r" "$3" "$5" || LESSON_STATUS=FAILED
      ;;
  esac
}

# finish: print the machine-readable status line; exit 0 unless the lesson failed.
finish() {
  printf '\nLESSON-STATUS: %s\n' "$LESSON_STATUS"
  [ "$LESSON_STATUS" != FAILED ]
}
