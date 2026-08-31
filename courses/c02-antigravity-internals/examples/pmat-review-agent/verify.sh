#!/bin/bash
# Proves the review can fail.
#
# The gate this agent runs is worth the number of times someone has seen it go
# red. So this plants a defect in a THROWAWAY COPY and asserts pmat reports it,
# and separately asserts a clean copy comes back with nothing.
#
# It also pins the one thing that will mislead a careless reviewer: pmat's exit
# code tracks BLOCKING violations only. A non-blocking finding leaves the gate
# PASSED and the exit code 0 while `Total violations` is above zero.

set -u

command -v pmat >/dev/null 2>&1 || { echo "FAIL: pmat is not installed"; exit 1; }

HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$HERE/../batch-runner"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

[ -d "$SRC/src" ] || { echo "FAIL: no source to review at $SRC"; exit 1; }
cp -r "$SRC/Cargo.toml" "$SRC/Cargo.lock" "$SRC/src" "$WORK/"

CHECKS=complexity,satd,dead-code
run() { (cd "$WORK" && pmat quality-gate --checks "$CHECKS" --fail-on-violation 2>&1); }
total() { printf '%s\n' "$1" | sed -n 's/^Total violations: *\([0-9]*\).*/\1/p' | head -1; }

problems=0
check() { # label got want
    if [ "$2" = "$3" ]; then printf '  PASS  %s\n' "$1"
    else printf '  FAIL  %s\n        expected [%s], got [%s]\n' "$1" "$3" "$2"; problems=$((problems + 1)); fi
}

OUT=$(run)
check "a clean copy reports no violations" "$(total "$OUT")" "0"

sed -i '1i // TODO: this is a hack, fix before shipping' "$WORK/src/worker.rs"
OUT=$(run)
check "a planted TODO is reported" "$(total "$OUT")" "1"

# The trap, pinned: the finding above is NOT blocking, so the gate still passes
# and the exit code is still 0. Anything reading only $? would call this clean.
OUT=$(run); EC=$?
check "the exit code alone would have missed it" "$EC" "0"

echo
if [ "$problems" -eq 0 ]; then echo "OK -- 3 checks passed."; exit 0; fi
echo "$problems check(s) failed."; exit 1
