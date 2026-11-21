#!/bin/bash
# Offline verifier for m2-getting-started-antigravity.
# Does NOT run live `agy`; verifies the launcher guardrail and session record,
# and proves that empty or unsafe artifacts are rejected.

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

check_launch_script() {
    local script="$1"
    [ -s "$script" ] || return 1
    bash -n "$script" >/dev/null 2>&1 || return 1
    grep -Eq '^[[:space:]]*set[[:space:]]+-euo[[:space:]]+pipefail' "$script" || return 1
    grep -q 'agy -p' "$script" || return 1
    grep -q -- '--mode plan' "$script" || return 1
}

check_session_record() {
    local record="$1"
    [ -s "$record" ] || return 1
    grep -Eq '^MODE=plan$' "$record" || return 1
    grep -Eq '^READ_ONLY=true$' "$record" || return 1
    grep -Eq '^FILES_OBSERVED=.+' "$record" || return 1
}

if check_launch_script "$HERE/explore-workspace.sh"; then
    pass "explore-workspace.sh enforces --mode plan and passes bash -n"
else
    fail "explore-workspace.sh failed launcher contract"
fi

if check_session_record "$HERE/expected-session.txt"; then
    pass "expected-session.txt satisfies read-only session contract"
else
    fail "expected-session.txt failed session contract"
fi

: > "$WORK/empty.sh"
if check_launch_script "$WORK/empty.sh"; then
    fail "empty launcher script was accepted"
else
    pass "empty launcher script is rejected"
fi

sed 's/--mode plan//' "$HERE/explore-workspace.sh" > "$WORK/unsafe.sh"
if check_launch_script "$WORK/unsafe.sh"; then
    fail "launcher missing --mode plan was accepted"
else
    pass "launcher missing --mode plan is rejected"
fi

: > "$WORK/empty-session.txt"
if check_session_record "$WORK/empty-session.txt"; then
    fail "empty session record was accepted"
else
    pass "empty session record is rejected"
fi

sed 's/READ_ONLY=true/READ_ONLY=false/' "$HERE/expected-session.txt" > "$WORK/mutated-session.txt"
if check_session_record "$WORK/mutated-session.txt"; then
    fail "non-read-only session record was accepted"
else
    pass "non-read-only session record is rejected"
fi

echo
if [ "$FAILED" -eq 0 ]; then
    echo "contract: m2-getting-started-antigravity OK"
    exit 0
fi
echo "$FAILED check(s) failed." >&2
exit 1
