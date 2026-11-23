#!/usr/bin/env bash
# No Python anywhere: no .py files, no python/uvx call in a script or workflow.
# NOPY_FILES (newline-separated paths) replaces the git file list; the tests use it.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
files="${NOPY_FILES-$(git ls-files)}"
n=$(echo "$files" | grep -c . || true)
py=$(echo "$files" | grep -c '\.py$' || true)
scan=$(echo "$files" | grep -v -e '^scripts/gate-nopython.sh$' -e '^README.md$' -e '^DEMO-STATUS.md$' || true)
calls=0
for f in $scan; do
  c=$(grep -cE '(^|[^A-Za-z_-])(python3?|uvx|pip3?) ' "$f" || true)
  calls=$((calls + c))
done
echo "nopython: scanned $n tracked files, $py .py files, $calls python/uvx/pip calls"
if [ "$n" -eq 0 ]; then
  echo "FAIL scanned 0 files"
  exit 1
fi
if [ "$py" -ne 0 ] || [ "$calls" -ne 0 ]; then
  echo "FAIL"
  exit 1
fi
echo "nopython OK"
