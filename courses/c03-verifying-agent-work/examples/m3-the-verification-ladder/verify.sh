#!/bin/bash
# Verifies the Verification Ladder passes on true transpose and fails on wrong rotation and empty scripts.

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

INPUT="$HERE/fixtures/matrix-3x2.txt"
LADDER="$HERE/ladder.sh"

# 1. Correct transpose must pass all 3 rungs.
bash "$LADDER" "$INPUT" "$HERE/transpose-matrix.sh"
echo "  PASS  true transpose cleared all rungs"

# 2. Wrong 90-degree rotation must pass Rungs 1-2 but FAIL Rung 3.
set +e
ROT_OUT="$(bash "$LADDER" "$INPUT" "$HERE/wrong-rotate.sh" 2>&1)"
ROT_RC=$?
set -e
if [ "$ROT_RC" -eq 0 ]; then
    echo "  FAIL  ladder accepted wrong-rotate.sh" >&2
    exit 1
fi
printf '%s\n' "$ROT_OUT" | grep -q 'Rung 2 PASS' || { echo "  FAIL  expected rotation to pass Rung 2" >&2; exit 1; }
printf '%s\n' "$ROT_OUT" | grep -q 'Rung 3 FAIL' || { echo "  FAIL  expected rotation to fail Rung 3" >&2; exit 1; }
echo "  PASS  wrong rotation passed Rungs 1-2 and failed Rung 3"

# 3. Empty/no-op script must fail.
: > "$WORK/empty.sh"
if bash "$LADDER" "$INPUT" "$WORK/empty.sh" >/dev/null 2>&1; then
    echo "  FAIL  ladder accepted an empty script" >&2
    exit 1
fi
echo "  PASS  empty script rejected"

echo "contract: m3-the-verification-ladder OK"
