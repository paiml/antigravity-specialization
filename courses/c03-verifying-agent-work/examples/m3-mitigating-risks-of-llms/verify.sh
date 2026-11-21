#!/bin/bash
# Verifies guardrail-check.sh passes on clean output and fails on every planted risk.

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

GATE="$HERE/guardrail-check.sh"
RULE="$HERE/.agents/rules/guardrails.md"
SAMPLE="$HERE/sample-agent-output"

[ -s "$RULE" ] || { echo "FAIL: missing rule file $RULE" >&2; exit 1; }
grep -q 'guardrail-check.sh' "$RULE" || { echo "FAIL: rule does not reference guardrail-check.sh" >&2; exit 1; }

# 1. Clean sample must pass.
bash "$GATE" "$SAMPLE" >/dev/null
echo "  PASS  clean sample passes guardrail gate"

# 2. Empty deliverable must fail.
cp -r "$SAMPLE" "$WORK/bad-empty"
: > "$WORK/bad-empty/transform.sh"
if bash "$GATE" "$WORK/bad-empty" >/dev/null 2>&1; then
    echo "  FAIL  guardrail gate accepted an empty deliverable" >&2
    exit 1
fi
echo "  PASS  empty deliverable rejected"

# 3. Path traversal must fail.
cp -r "$SAMPLE" "$WORK/bad-traversal"
printf '\ncat ../../etc/passwd >/dev/null\n' >> "$WORK/bad-traversal/transform.sh"
if bash "$GATE" "$WORK/bad-traversal" >/dev/null 2>&1; then
    echo "  FAIL  guardrail gate accepted path traversal" >&2
    exit 1
fi
echo "  PASS  path traversal rejected"

# 4. Disallowed runtime (.py) must fail.
cp -r "$SAMPLE" "$WORK/bad-runtime"
printf 'print("hi")\n' > "$WORK/bad-runtime/helper.py"
if bash "$GATE" "$WORK/bad-runtime" >/dev/null 2>&1; then
    echo "  FAIL  guardrail gate accepted a .py file" >&2
    exit 1
fi
echo "  PASS  disallowed runtime rejected"

# 5. Hardcoded secret must fail.
cp -r "$SAMPLE" "$WORK/bad-secret"
printf '\nAPI_KEY="sk-live-secret-1234"\n' >> "$WORK/bad-secret/transform.sh"
if bash "$GATE" "$WORK/bad-secret" >/dev/null 2>&1; then
    echo "  FAIL  guardrail gate accepted a hardcoded secret" >&2
    exit 1
fi
echo "  PASS  hardcoded secret rejected"

echo "contract: m3-mitigating-risks-of-llms OK"
