#!/bin/bash
# Verifies m2-antigravity-artifacts and proves incomplete or empty artifacts fail.

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

FAILED=0

pass() {
    echo "  PASS  $1"
}

fail() {
    echo "  FAIL  $1"
    FAILED=$((FAILED + 1))
}

copy_artifacts() {
    local dest="$1"
    mkdir -p "$dest"
    cp "$HERE/implementation_plan.md" "$HERE/task.md" "$HERE/walkthrough.md" "$dest/"
}

if bash -n "$HERE/check-artifacts.sh"; then
    pass "check-artifacts.sh passes bash -n"
else
    fail "check-artifacts.sh failed syntax check"
fi

if bash "$HERE/check-artifacts.sh" "$HERE" >/dev/null 2>&1; then
    pass "valid artifact set passes"
else
    fail "valid artifact set was rejected"
fi

copy_artifacts "$WORK/case1"
: > "$WORK/case1/implementation_plan.md"
if bash "$HERE/check-artifacts.sh" "$WORK/case1" >/dev/null 2>&1; then
    fail "empty implementation_plan.md was accepted"
else
    pass "empty implementation_plan.md is rejected"
fi

mkdir -p "$WORK/case2"
grep -v '^## Verification Plan$' "$HERE/implementation_plan.md" > "$WORK/case2/implementation_plan.md"
cp "$HERE/task.md" "$HERE/walkthrough.md" "$WORK/case2/"
if bash "$HERE/check-artifacts.sh" "$WORK/case2" >/dev/null 2>&1; then
    fail "plan missing Verification Plan was accepted"
else
    pass "plan missing Verification Plan is rejected"
fi

copy_artifacts "$WORK/case3"
printf '%s\n' '- TBD' >> "$WORK/case3/walkthrough.md"
if bash "$HERE/check-artifacts.sh" "$WORK/case3" >/dev/null 2>&1; then
    fail "walkthrough with TBD was accepted"
else
    pass "walkthrough with TBD is rejected"
fi

copy_artifacts "$WORK/case4"
printf '%s\n' '# Tasks' > "$WORK/case4/task.md"
if bash "$HERE/check-artifacts.sh" "$WORK/case4" >/dev/null 2>&1; then
    fail "task.md with no checklist items was accepted"
else
    pass "task.md with no checklist items is rejected"
fi

echo
if [ "$FAILED" -eq 0 ]; then
    echo "contract: m2-antigravity-artifacts OK"
    exit 0
fi
echo "$FAILED check(s) failed." >&2
exit 1
