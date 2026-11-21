#!/bin/bash
# Verifies the Red-Green TDD contract:
# 1. Broken stub MUST fail the suite (RED).
# 2. Complete implementation MUST pass all 6 cases (GREEN).
# 3. Empty and wrong-constant stubs MUST fail.

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

SUITE="$HERE/test_slugify.sh"

# 1. RED: broken stub must fail.
if bash "$SUITE" "$HERE/slugify_red.sh" >/dev/null 2>&1; then
    echo "  FAIL  TDD suite passed on broken RED stub" >&2
    exit 1
fi
echo "  PASS  RED stub failed TDD suite as expected"

# 2. GREEN: fixed implementation must pass.
bash "$SUITE" "$HERE/slugify_green.sh" >/dev/null
echo "  PASS  GREEN implementation passed all 6 TDD cases"

# 3. Empty script must fail.
: > "$WORK/empty.sh"
if bash "$SUITE" "$WORK/empty.sh" >/dev/null 2>&1; then
    echo "  FAIL  TDD suite accepted an empty script" >&2
    exit 1
fi
echo "  PASS  empty script rejected"

# 4. Wrong constant stub must fail.
printf '#!/bin/bash\necho "always-wrong"\n' > "$WORK/wrong.sh"
if bash "$SUITE" "$WORK/wrong.sh" >/dev/null 2>&1; then
    echo "  FAIL  TDD suite accepted a constant wrong stub" >&2
    exit 1
fi
echo "  PASS  wrong stub rejected"

echo "contract: m4-using-test-driven-development OK"
