#!/bin/bash
# Strict pmat quality-gate wrapper.
# Refuses empty scopes, missing Total violations, or any non-zero violation count
# even when pmat itself exits 0 on non-blocking findings.

set -euo pipefail

TARGET="${1:-}"
if [ -z "$TARGET" ] || [ ! -d "$TARGET" ]; then
    echo "Usage: $0 <project-dir>" >&2
    exit 1
fi

command -v pmat >/dev/null 2>&1 || {
    echo "FAIL: pmat is not installed on PATH" >&2
    exit 1
}

src_count="$(find "$TARGET" -maxdepth 4 -type f \( -name '*.rs' -o -name '*.c' -o -name '*.h' -o -name '*.go' \) | wc -l | awk '{print $1}')"
if [ "$src_count" -eq 0 ]; then
    echo "FAIL: anti-vacuity — no analyzable source files found in $TARGET" >&2
    exit 1
fi

set +e
OUT="$(cd "$TARGET" && pmat quality-gate --checks complexity,satd,dead-code --fail-on-violation 2>&1)"
EC=$?
set -e

TOTAL="$(printf '%s\n' "$OUT" | sed -n 's/^Total violations: *\([0-9][0-9]*\).*/\1/p' | head -1)"
if [ -z "$TOTAL" ]; then
    echo "FAIL: pmat output did not include 'Total violations'" >&2
    printf '%s\n' "$OUT" >&2
    exit 1
fi

if printf '%s\n' "$OUT" | grep -Eiq 'analy[sz]ed 0 of [0-9]+ file'; then
    echo "FAIL: anti-vacuity — pmat analysed 0 files" >&2
    exit 1
fi

if [ "$TOTAL" -ne 0 ] || [ "$EC" -ne 0 ]; then
    echo "FAIL: pmat reported Total violations=$TOTAL (exit=$EC)" >&2
    printf '%s\n' "$OUT" >&2
    exit 1
fi

echo "pmat-gate passed: Total violations=0 across $src_count source file(s)."
