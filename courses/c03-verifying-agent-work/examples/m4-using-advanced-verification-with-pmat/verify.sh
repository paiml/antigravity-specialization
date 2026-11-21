#!/bin/bash
# Verifies pmat-gate.sh passes on clean code, catches a planted TODO even when
# raw pmat exits 0, and rejects an empty directory.

set -euo pipefail

command -v pmat >/dev/null 2>&1 || {
    echo "FAIL: pmat is not installed" >&2
    exit 1
}

HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

GATE="$HERE/pmat-gate.sh"
FIXTURE="$HERE/fixture"

[ -f "$FIXTURE/src/lib.rs" ] || { echo "FAIL: missing fixture at $FIXTURE" >&2; exit 1; }

# 1. Clean copy must pass.
cp -r "$FIXTURE" "$WORK/clean"
bash "$GATE" "$WORK/clean" >/dev/null
echo "  PASS  clean fixture passed pmat-gate"

# 2. Planted TODO leaves raw pmat exiting 0, but pmat-gate.sh must fail.
cp -r "$FIXTURE" "$WORK/satd"
{ printf '// TODO: bypass verification before release\n'; cat "$WORK/satd/src/lib.rs"; } > "$WORK/satd/src/lib.rs.tmp"
mv "$WORK/satd/src/lib.rs.tmp" "$WORK/satd/src/lib.rs"

set +e
RAW_OUT="$(cd "$WORK/satd" && pmat quality-gate --checks complexity,satd,dead-code --fail-on-violation 2>&1)"
RAW_EC=$?
set -e
if [ "$RAW_EC" -ne 0 ]; then
    echo "  FAIL  expected raw pmat to exit 0 on non-blocking TODO, got exit $RAW_EC" >&2
    printf '%s\n' "$RAW_OUT" >&2
    exit 1
fi
if bash "$GATE" "$WORK/satd" >/dev/null 2>&1; then
    echo "  FAIL  pmat-gate accepted planted TODO" >&2
    exit 1
fi
echo "  PASS  planted TODO caught by pmat-gate despite raw exit 0"

# 3. Empty directory must fail anti-vacuity check.
mkdir -p "$WORK/empty"
if bash "$GATE" "$WORK/empty" >/dev/null 2>&1; then
    echo "  FAIL  pmat-gate accepted empty directory" >&2
    exit 1
fi
echo "  PASS  empty directory rejected"

echo "contract: m4-using-advanced-verification-with-pmat OK"
