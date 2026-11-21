#!/bin/bash
# Verifies the sample GitHub Actions workflow and proves check-workflow.sh rejects bad inputs.

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if [ "${1:-}" = "--self-test" ]; then
    bash "$HERE/check-workflow.sh" --self-test
    exit 0
fi

echo "1. Self-testing check-workflow.sh..."
bash "$HERE/check-workflow.sh" --self-test

echo "2. Validating .github/workflows/verify.yml..."
bash "$HERE/check-workflow.sh" "$HERE/.github/workflows/verify.yml" "$HERE"

echo "3. Running workflow smoke script..."
bash "$HERE/scripts/smoke.sh"

echo "4. Verifying empty and broken workflows fail..."
: > "$WORK/empty.yml"
set +e
bash "$HERE/check-workflow.sh" "$WORK/empty.yml" "$HERE" >/dev/null 2>&1
EMPTY_EC=$?
set -e
[ "$EMPTY_EC" -ne 0 ] || { echo "FAIL: empty workflow passed" >&2; exit 1; }

cat > "$WORK/missing-script.yml" <<'EOF'
name: Broken Script Ref
on: push
permissions:
  contents: read
jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: bash ./scripts/does-not-exist.sh
EOF
set +e
bash "$HERE/check-workflow.sh" "$WORK/missing-script.yml" "$HERE" >/dev/null 2>&1
MISS_EC=$?
set -e
[ "$MISS_EC" -ne 0 ] || { echo "FAIL: missing script reference passed" >&2; exit 1; }

echo "contract: m5-github-actions-intro OK"
