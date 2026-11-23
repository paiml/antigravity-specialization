#!/usr/bin/env bash
# Lesson 1.1.2: Antigravity project setup and context.
# RUNS: every `make` command the context file names must exist in the Makefile (checked here).
# BLOCKED when agy has no quota: the agent session that loads CONTEXT.md.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
new_workdir
copy_ms ch1-done "$WORK/app"
say "the context file the agent reads first"
sed -n '1,12p' "$WORK/app/CONTEXT.md"
say "agent project setup (print mode, plan mode: it reads, it does not edit)"
agy_step "$here/prompts/load-context.md" plan "$WORK/app"
say "every make command in CONTEXT.md must be a real target"
bad=0
for t in $(grep -oE 'make [a-z]+' "$WORK/app/CONTEXT.md" | sed 's/make //' | sort -u); do
  if grep -q "^$t:" "$WORK/app/Makefile"; then echo "ok    make $t"; else echo "FAIL  make $t is not in the Makefile"; bad=1; fi
done
if [ "$bad" -ne 0 ]; then exit 1; fi
say "a context file that names a missing target is caught"
printf 'Run `make deploy-all` to ship.\n' >>"$WORK/app/CONTEXT.md"
t=$(grep -oE 'make [a-z-]+' "$WORK/app/CONTEXT.md" | tail -n 1 | sed 's/make //')
if grep -q "^$t:" "$WORK/app/Makefile"; then echo "FAIL a missing target passed"; exit 1; fi
echo "caught: make $t is not a target"
