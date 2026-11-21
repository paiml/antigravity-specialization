#!/bin/bash
# Offline verifier for m2-create-first-agent.
# Does NOT run live `agy`; verifies the agent spec and scripts offline,
# and proves that empty or malformed agent files are rejected.

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

for s in "$HERE/run-agent.sh" "$HERE/validate-agent.sh"; do
    if bash -n "$s"; then
        pass "$(basename "$s") passes bash -n"
    else
        fail "$(basename "$s") failed syntax check"
    fi
done

if grep -q 'agy -p' "$HERE/run-agent.sh" && grep -q -- '--mode plan' "$HERE/run-agent.sh"; then
    pass "run-agent.sh invokes agy -p with --mode plan"
else
    fail "run-agent.sh missing agy -p or --mode plan"
fi

if bash "$HERE/validate-agent.sh" "$HERE/agents/verify-first.md" >/dev/null 2>&1; then
    pass "agents/verify-first.md passes validation"
else
    fail "agents/verify-first.md failed validation"
fi

: > "$WORK/empty.md"
if bash "$HERE/validate-agent.sh" "$WORK/empty.md" >/dev/null 2>&1; then
    fail "empty agent file was accepted"
else
    pass "empty agent file is rejected"
fi

cat > "$WORK/no-fm.md" <<'EOF'
# Agent Without Frontmatter
Just prose.
EOF
if bash "$HERE/validate-agent.sh" "$WORK/no-fm.md" >/dev/null 2>&1; then
    fail "agent without frontmatter was accepted"
else
    pass "agent without frontmatter is rejected"
fi

cat > "$WORK/no-desc.md" <<'EOF'
---
name: incomplete_agent
---

# Incomplete Agent
Missing description.
EOF
if bash "$HERE/validate-agent.sh" "$WORK/no-desc.md" >/dev/null 2>&1; then
    fail "agent missing description was accepted"
else
    pass "agent missing description is rejected"
fi

cat > "$WORK/no-body.md" <<'EOF'
---
name: empty_body_agent
description: "Has frontmatter but no instructions."
---
EOF
if bash "$HERE/validate-agent.sh" "$WORK/no-body.md" >/dev/null 2>&1; then
    fail "agent with empty body was accepted"
else
    pass "agent with empty body is rejected"
fi

echo
if [ "$FAILED" -eq 0 ]; then
    echo "contract: m2-create-first-agent OK"
    exit 0
fi
echo "$FAILED check(s) failed." >&2
exit 1
