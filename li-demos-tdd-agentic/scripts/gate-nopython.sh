#!/usr/bin/env bash
# No Python anywhere: no .py files, no python/uvx/pip call in a script or workflow.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
n=$(git ls-files | wc -l | tr -d ' ')
py=$(git ls-files | grep -c '\.py$' || true)
calls=$(git grep -nE '(^|[^A-Za-z_-])(python3?|uvx|pip3?) ' -- . ':!scripts/gate-nopython.sh' ':!README.md' ':!DEMO-STATUS.md' | wc -l | tr -d ' ')
echo "nopython: scanned $n tracked files, $py .py files, $calls python/uvx/pip calls"
if [ "$n" -eq 0 ]; then echo "FAIL scanned 0 files"; exit 1; fi
if [ "$py" -ne 0 ] || [ "$calls" -ne 0 ]; then echo "FAIL"; exit 1; fi
echo "nopython OK"
