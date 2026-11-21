#!/bin/bash
# Verifies referee.sh accepts valid submissions and rejects deceptive/empty ones.

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if [ "${1:-}" = "--self-test" ]; then
    bash "$HERE/referee.sh" --self-test
    exit 0
fi

echo "1. Self-testing referee failure modes..."
bash "$HERE/referee.sh" --self-test

echo "2. Checking good submission passes..."
bash "$HERE/referee.sh" "$HERE/submission-good"

echo "3. Checking bad submission fails..."
set +e
BAD_OUT="$(bash "$HERE/referee.sh" "$HERE/submission-bad" 2>&1)"
BAD_EC=$?
set -e
if [ "$BAD_EC" -eq 0 ]; then
    echo "FAIL: referee accepted submission-bad" >&2
    exit 1
fi
printf '  rejected as expected (exit %s): %s\n' "$BAD_EC" "$(printf '%s\n' "$BAD_OUT" | head -n 1)"

echo "4. Checking empty artifact fails..."
mkdir -p "$WORK/empty-sub"
set +e
bash "$HERE/referee.sh" "$WORK/empty-sub" >/dev/null 2>&1
EMPTY_EC=$?
set -e
if [ "$EMPTY_EC" -eq 0 ]; then
    echo "FAIL: referee accepted empty submission directory" >&2
    exit 1
fi

echo "contract: m5-why-ci-is-the-referee OK"
