#!/bin/bash
# Verifies m1-what-is-generative-ai against valid, drifted, empty, and wrong artifacts.

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

if bash -n "$HERE/check-samples.sh"; then
    pass "check-samples.sh passes bash -n"
else
    fail "check-samples.sh failed syntax check"
fi

if bash "$HERE/check-samples.sh" "$HERE/samples/candidate-valid.txt" >/dev/null 2>&1; then
    pass "compliant artifact is accepted"
else
    fail "compliant artifact was rejected"
fi

if bash "$HERE/check-samples.sh" "$HERE/samples/candidate-drifted.txt" >/dev/null 2>&1; then
    fail "drifted artifact was accepted"
else
    pass "drifted artifact is rejected"
fi

: > "$WORK/empty.txt"
if bash "$HERE/check-samples.sh" "$WORK/empty.txt" >/dev/null 2>&1; then
    fail "empty artifact was accepted"
else
    pass "empty artifact is rejected"
fi

cat > "$WORK/wrong-lines.txt" <<'EOF'
# CONTRACT v1
ARTIFACT=pyramid-nostar
LINE_COUNT=99
HEX_DIGEST=a3f1c9e2b4d807165a9c3e1f2d4b6a80c7e5d3b1a9f8e7d6c5b4a3f2e1d0c9b8
STATUS=verified
EOF
if bash "$HERE/check-samples.sh" "$WORK/wrong-lines.txt" >/dev/null 2>&1; then
    fail "wrong LINE_COUNT artifact was accepted"
else
    pass "wrong LINE_COUNT artifact is rejected"
fi

echo
if [ "$FAILED" -eq 0 ]; then
    echo "contract: m1-what-is-generative-ai OK"
    exit 0
fi
echo "$FAILED check(s) failed." >&2
exit 1
