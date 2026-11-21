#!/bin/bash
# Verifies m1-agentic-coding-evolution and proves it rejects empty or bad configs.

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

check_report() {
    local report="$1"
    [ -s "$report" ] || return 1
    grep -Eq '^SERVICE_NAME=[a-zA-Z0-9_-]+$' "$report" || return 1
    grep -Eq '^MAX_RETRIES=[1-9][0-9]*$' "$report" || return 1
    grep -Eq '^MODE=(strict|warn)$' "$report" || return 1
    grep -Eq '^VERIFIED=true$' "$report" || return 1
}

if bash -n "$HERE/evolve.sh"; then
    pass "evolve.sh passes bash -n"
else
    fail "evolve.sh failed syntax check"
fi

if bash "$HERE/evolve.sh" "$HERE/sample-config.env" "$WORK/ok.out" >/dev/null 2>&1 && check_report "$WORK/ok.out"; then
    pass "valid config produces a verified report"
else
    fail "valid config did not produce a valid report"
fi

: > "$WORK/empty.env"
if bash "$HERE/evolve.sh" "$WORK/empty.env" "$WORK/empty.out" >/dev/null 2>&1; then
    fail "empty config was accepted"
else
    pass "empty config was rejected"
fi

cat > "$WORK/bad.env" <<'EOF'
SERVICE_NAME=verifier
MAX_RETRIES=zero
EOF
if bash "$HERE/evolve.sh" "$WORK/bad.env" "$WORK/bad.out" >/dev/null 2>&1; then
    fail "malformed config was accepted"
else
    pass "malformed config was rejected"
fi

: > "$WORK/empty.report"
if check_report "$WORK/empty.report"; then
    fail "empty report passed check_report"
else
    pass "empty report failed check_report"
fi

cat > "$WORK/false.report" <<'EOF'
SERVICE_NAME=verifier
MAX_RETRIES=3
MODE=strict
VERIFIED=false
EOF
if check_report "$WORK/false.report"; then
    fail "unverified report passed check_report"
else
    pass "unverified report failed check_report"
fi

echo
if [ "$FAILED" -eq 0 ]; then
    echo "contract: m1-agentic-coding-evolution OK"
    exit 0
fi
echo "$FAILED check(s) failed." >&2
exit 1
