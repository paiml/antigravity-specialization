#!/usr/bin/env bash
set -uo pipefail
. "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
# 4.1 Rules the agent reads (AGENTS.md) and a hook that refuses a red commit.
# The hook shown is a plain git hook. Antigravity's own hook configuration is NOT used here (not verified).
banner "AGENTS.md the agent reads"
cat "$ROOT/project/AGENTS.md"
d=$(new_work hook)
stage_into "$d" n-green
git -C "$d" init -q
mkdir -p "$d/.git/hooks"
cp "$ROOT/project/hooks/pre-commit" "$d/.git/hooks/pre-commit"
chmod +x "$d/.git/hooks/pre-commit"
git -C "$d" add -A
banner "commit with green tests"
git -C "$d" -c user.name=demo -c user.email=demo@example.invalid commit -q -m "green" >/dev/null && echo "commit accepted"
cp "$ROOT/stages/stub/src/slugify.sh" "$d/src/slugify.sh"
git -C "$d" add -A
banner "commit with red tests: must be refused"
if git -C "$d" -c user.name=demo -c user.email=demo@example.invalid commit -q -m "red" >/dev/null 2>&1; then
  echo "commit accepted (unexpected)"
  LESSON_STATUS=FAILED
else
  echo "commit refused by the hook"
fi
finish
