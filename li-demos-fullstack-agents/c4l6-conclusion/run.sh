#!/usr/bin/env bash
# Lesson 4.1.6: Course conclusion and next steps. RUNS: a scratch repository is built from the four milestones, one commit and one tag
# each, the tests are run at every tag, and the log is printed. No agent step.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
need_node || exit 1
new_workdir
g() { git -c core.hooksPath=/dev/null -c user.name=demo -c user.email=demo "$@"; }
mkdir -p "$WORK/repo"
cd "$WORK/repo" || exit 1
g init -q -b main
for ms in ch1-done ch2-done ch3-done v1.0.0; do
  find . -mindepth 1 -maxdepth 1 -not -name .git -exec rm -rf -- {} +
  copy_ms "$ms" "$WORK/repo"
  summary=$(node --test --test-force-exit 2>&1 | grep -E '^# (pass|fail)' | tr '\n' ' ')
  echo "$ms: $summary"
  case "$summary" in *'# fail 0'*) ;; *) echo "FAIL tests at $ms"; exit 1 ;; esac
  g add -A
  g commit -q -m "$ms"
  g tag "$ms"
done
say "the history"
g log --oneline --decorate | sed 's/^/  /'
say "NEXT STEPS: add a second board, due dates or a real login; each starts with a line in SPEC.md and a failing test"
