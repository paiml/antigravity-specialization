#!/bin/bash
# Verifies sample-verified-repo passes audit-repo.sh and broken/empty repos fail.

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if [ "${1:-}" = "--self-test" ]; then
    bash "$HERE/audit-repo.sh" --self-test
    exit 0
fi

assert_fails() {
    local label="$1"
    local dir="$2"
    local ec
    set +e
    bash "$HERE/audit-repo.sh" "$dir" >/dev/null 2>&1
    ec=$?
    set -e
    if [ "$ec" -eq 0 ]; then
        echo "FAIL: $label unexpectedly passed" >&2
        exit 1
    fi
    echo "  PASS (rejected): $label"
}

echo "1. Self-testing audit-repo.sh..."
bash "$HERE/audit-repo.sh" --self-test

echo "2. Auditing sample-verified-repo..."
bash "$HERE/audit-repo.sh" "$HERE/sample-verified-repo"

echo "3. Testing failure modes..."
mkdir -p "$WORK/empty-repo"
assert_fails "empty repository" "$WORK/empty-repo"

cp -r "$HERE/sample-verified-repo" "$WORK/dangling-manifest"
rm -f "$WORK/dangling-manifest/data/input.txt"
assert_fails "dangling artifact in project.toml" "$WORK/dangling-manifest"

cp -r "$HERE/sample-verified-repo" "$WORK/ci-drift"
sed -i 's|./scripts/check.sh|echo skipped|' "$WORK/ci-drift/.github/workflows/ci.yml"
assert_fails "CI workflow drift from AGENTS.md/project.toml" "$WORK/ci-drift"

echo "contract: m6-anatomy-of-a-verified-repo OK"
