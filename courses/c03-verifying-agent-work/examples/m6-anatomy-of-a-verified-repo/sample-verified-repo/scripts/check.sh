#!/bin/bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

bash "$HERE/scripts/build.sh" "$HERE/data/input.txt" "$WORK/report.txt"
grep -q '^lines=3$' "$WORK/report.txt" || { echo "FAIL: expected lines=3" >&2; exit 1; }
grep -q '^words=7$' "$WORK/report.txt" || { echo "FAIL: expected words=7" >&2; exit 1; }
echo "PASS: build.sh produced exact counts for data/input.txt"

: > "$WORK/empty.txt"
set +e
bash "$HERE/scripts/build.sh" "$WORK/empty.txt" "$WORK/empty-out.txt" >/dev/null 2>&1
EMPTY_EC=$?
set -e
[ "$EMPTY_EC" -ne 0 ] || { echo "FAIL: build.sh accepted empty input" >&2; exit 1; }
echo "PASS: build.sh rejects empty input"
