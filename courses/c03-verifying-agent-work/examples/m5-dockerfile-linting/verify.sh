#!/bin/bash
# Verifies PR Dockerfile workflow and proves lint-dockerfile.sh rejects bad/empty files.

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if [ "${1:-}" = "--self-test" ]; then
    bash "$HERE/lint-dockerfile.sh" --self-test
    exit 0
fi

echo "1. Self-testing lint-dockerfile.sh..."
bash "$HERE/lint-dockerfile.sh" --self-test

echo "2. Checking PR workflow triggers on pull_request and Dockerfile paths..."
WF="$HERE/.github/workflows/dockerfile-lint.yml"
grep -q 'pull_request:' "$WF" || { echo "FAIL: workflow missing pull_request trigger" >&2; exit 1; }
grep -q 'Dockerfile' "$WF" || { echo "FAIL: workflow missing Dockerfile path filter" >&2; exit 1; }

echo "3. Checking Dockerfile.good passes..."
bash "$HERE/lint-dockerfile.sh" "$HERE/Dockerfile.good"

echo "4. Checking Dockerfile.bad fails with violations..."
set +e
BAD_OUT="$(bash "$HERE/lint-dockerfile.sh" "$HERE/Dockerfile.bad" 2>&1)"
BAD_EC=$?
set -e
[ "$BAD_EC" -ne 0 ] || { echo "FAIL: Dockerfile.bad passed lint" >&2; exit 1; }
for code in DL3007 DL3015 DL3009 DL3003 DL3020 CIS-DI-0001; do
    if ! printf '%s\n' "$BAD_OUT" | grep -q "$code"; then
        echo "FAIL: expected violation code $code not reported for Dockerfile.bad" >&2
        printf '%s\n' "$BAD_OUT" >&2
        exit 1
    fi
done
echo "  reported all expected violations (DL3007, DL3015, DL3009, DL3003, DL3020, CIS-DI-0001)"

echo "5. Checking empty and non-Dockerfile inputs fail..."
: > "$WORK/Dockerfile.empty"
set +e
bash "$HERE/lint-dockerfile.sh" "$WORK/Dockerfile.empty" >/dev/null 2>&1
EMPTY_EC=$?
set -e
[ "$EMPTY_EC" -ne 0 ] || { echo "FAIL: empty Dockerfile passed" >&2; exit 1; }

echo "just some text without FROM" > "$WORK/not-a-dockerfile"
set +e
bash "$HERE/lint-dockerfile.sh" "$WORK/not-a-dockerfile" >/dev/null 2>&1
NOFROM_EC=$?
set -e
[ "$NOFROM_EC" -ne 0 ] || { echo "FAIL: file without FROM passed" >&2; exit 1; }

echo "contract: m5-dockerfile-linting OK"
