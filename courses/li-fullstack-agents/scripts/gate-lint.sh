#!/usr/bin/env bash
# bashrs lint over every tracked shell script. Prints the file count so "0 files" cannot pass.
# LINT_FILES (newline-separated paths) replaces the git file list; the tests use it.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
files="${LINT_FILES-$(git ls-files '*.sh' '*/run.sh' | sort -u)}"
n=$(echo "$files" | grep -c . || true)
echo "lint: $n shell files"
if [ "$n" -eq 0 ]; then
  echo "FAIL scanned 0 files"
  exit 1
fi
bad=0
for f in $files; do
  # --level error: the gate fails on errors; warnings are counted separately by scripts/lint-warnings.sh
  if ! bashrs lint --level error "$f" >/dev/null 2>&1; then
    echo "LINT FAIL $f"
    bad=1
  fi
done
if [ "$bad" -ne 0 ]; then exit 1; fi
echo "lint OK"
