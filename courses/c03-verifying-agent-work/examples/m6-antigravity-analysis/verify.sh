#!/bin/bash
# Offline verification for m6-antigravity-analysis.
# Does NOT invoke live `agy` (example.toml marks it live in requires).

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if [ "${1:-}" = "--self-test" ]; then
    bash "$HERE/check-analysis.sh" --self-test
    exit 0
fi

assert_fails() {
    local label="$1"
    local report="$2"
    local ec
    set +e
    bash "$HERE/check-analysis.sh" "$HERE/target-repo" "$report" >/dev/null 2>&1
    ec=$?
    set -e
    if [ "$ec" -eq 0 ]; then
        echo "FAIL: $label unexpectedly passed" >&2
        exit 1
    fi
    echo "  PASS (rejected): $label"
}

echo "1. Checking example.toml the live marker and analyze.sh --mode plan safety..."
grep -qF 'Live: needs agy' "$HERE/example.toml" || {
    echo "FAIL: example.toml requires does not say 'Live: needs agy'" >&2
    exit 1
}
bash -n "$HERE/analyze.sh"
grep -q -- '--mode plan' "$HERE/analyze.sh" || {
    echo "FAIL: analyze.sh must pass --mode plan" >&2
    exit 1
}

echo "2. Self-testing check-analysis.sh..."
bash "$HERE/check-analysis.sh" --self-test

echo "3. Verifying sample-analysis.md against target-repo..."
bash "$HERE/check-analysis.sh" "$HERE/target-repo" "$HERE/sample-analysis.md"

echo "4. Testing hallucination and omission failure modes..."
: > "$WORK/empty.md"
assert_fails "empty analysis report" "$WORK/empty.md"

sed 's|scripts/process.sh:4|scripts/ghost.sh:1|' "$HERE/sample-analysis.md" > "$WORK/ghost.md"
assert_fails "hallucinated file path" "$WORK/ghost.md"

sed 's|scripts/process.sh:4|scripts/process.sh:999|' "$HERE/sample-analysis.md" > "$WORK/oob.md"
assert_fails "out-of-range line number" "$WORK/oob.md"

grep -v 'tests/test_process.sh' "$HERE/sample-analysis.md" > "$WORK/incomplete.md"
assert_fails "incomplete report missing test finding" "$WORK/incomplete.md"

echo "contract: m6-antigravity-analysis OK"
