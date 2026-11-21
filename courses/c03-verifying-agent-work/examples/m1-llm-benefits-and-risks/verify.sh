#!/bin/bash
# Verifies m1-llm-benefits-and-risks and proves it rejects empty and risky drafts.

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

for s in "$HERE/audit-draft.sh" "$HERE/fixtures/good-script.sh" "$HERE/fixtures/risky-script.sh"; do
    if bash -n "$s"; then
        pass "$(basename "$s") passes bash -n"
    else
        fail "$(basename "$s") failed syntax check"
    fi
done

if bash "$HERE/audit-draft.sh" "$HERE/fixtures/good-script.sh" "$HERE" >/dev/null 2>&1; then
    pass "good-script.sh passes audit"
else
    fail "good-script.sh failed audit"
fi

if bash "$HERE/audit-draft.sh" "$HERE/fixtures/risky-script.sh" "$HERE" >/dev/null 2>&1; then
    fail "risky-script.sh was accepted"
else
    pass "risky-script.sh is rejected"
fi

: > "$WORK/empty.sh"
if bash "$HERE/audit-draft.sh" "$WORK/empty.sh" "$HERE" >/dev/null 2>&1; then
    fail "empty script was accepted"
else
    pass "empty script is rejected"
fi

sed 's|fixtures/target.txt|fixtures/missing.txt|' "$HERE/fixtures/good-script.sh" > "$WORK/hallucinated-path.sh"
if bash "$HERE/audit-draft.sh" "$WORK/hallucinated-path.sh" "$HERE" >/dev/null 2>&1; then
    fail "hallucinated path script was accepted"
else
    pass "hallucinated path script is rejected"
fi

printf '%s\n' '# TODO: verify later' >> "$WORK/todo.sh"
cat "$HERE/fixtures/good-script.sh" >> "$WORK/todo.sh"
if bash "$HERE/audit-draft.sh" "$WORK/todo.sh" "$HERE" >/dev/null 2>&1; then
    fail "script with TODO was accepted"
else
    pass "script with TODO is rejected"
fi

echo
if [ "$FAILED" -eq 0 ]; then
    echo "contract: m1-llm-benefits-and-risks OK"
    exit 0
fi
echo "$FAILED check(s) failed." >&2
exit 1
