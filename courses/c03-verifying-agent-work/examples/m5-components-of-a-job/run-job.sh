#!/bin/bash
# Simulates job execution in dependency order inside an isolated temp workspace.
# Stops downstream dependent jobs when an upstream job fails.

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
WF="${1:-$HERE/.github/workflows/pipeline.yml}"
SRC_ROOT="${2:-$HERE}"

bash "$HERE/inspect-jobs.sh" "$WF" >/dev/null

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

[ -d "$SRC_ROOT/scripts" ] || { echo "FAIL: missing scripts/ in $SRC_ROOT" >&2; exit 1; }
cp -r "$SRC_ROOT/scripts" "$WORK/scripts"

MARKER_DIR="$WORK/markers"
mkdir -p "$MARKER_DIR"

echo "[job: lint]"
(cd "$WORK" && bash -n ./scripts/app.sh)
touch "$MARKER_DIR/lint.ok"

if [ -f "$MARKER_DIR/lint.ok" ]; then
    echo "[job: test]"
    (cd "$WORK" && STRICT_MODE=1 bash ./scripts/app.sh --test)
    touch "$MARKER_DIR/test.ok"
fi

if [ -f "$MARKER_DIR/lint.ok" ] && [ -f "$MARKER_DIR/test.ok" ]; then
    echo "[job: package]"
    TARGET_ENV=ci
    echo "packaged TARGET_ENV=$TARGET_ENV"
    touch "$MARKER_DIR/package.ok"
fi

echo "JOB PIPELINE PASS"
