#!/bin/bash
# Verifies strict vs permissive contrast, rubric classification, and bad-input refusal.

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# 1. Strict mode catches what permissive mode masks.
CONTRAST_OUT="$(bash "$HERE/strict-vs-permissive.sh")"
printf '%s\n' "$CONTRAST_OUT" | grep -qx 'PERMISSIVE_RC=0' || { echo "FAIL: unexpected permissive rc" >&2; exit 1; }
printf '%s\n' "$CONTRAST_OUT" | grep -Eq '^STRICT_RC=[1-9][0-9]*$' || { echo "FAIL: unexpected strict rc" >&2; exit 1; }
echo "  PASS  strict mode catches unset variable and pipe failure"

# 2. Rubric classification on valid table.
EVAL_OUT="$(bash "$HERE/evaluate-languages.sh" "$HERE/languages.tsv")"
printf '%s\n' "$EVAL_OUT" | grep -Eq '^rust	12	SUITABLE$' || { echo "FAIL: rust classification mismatch" >&2; exit 1; }
printf '%s\n' "$EVAL_OUT" | grep -Eq '^bash-permissive	3	UNSAFE_WITHOUT_GATES$' || { echo "FAIL: bash-permissive classification mismatch" >&2; exit 1; }
echo "  PASS  rubric classifies strict vs permissive languages"

# 3. Empty file must fail.
: > "$WORK/empty.tsv"
if bash "$HERE/evaluate-languages.sh" "$WORK/empty.tsv" >/dev/null 2>&1; then
    echo "FAIL: evaluator accepted empty TSV" >&2
    exit 1
fi
echo "  PASS  empty TSV rejected"

# 4. Out-of-range score must fail.
cat > "$WORK/bad-score.tsv" <<'EOF'
language	static_types	fail_fast_errors	deterministic_tooling	fast_gate_cli
rust	9	3	3	3
EOF
if bash "$HERE/evaluate-languages.sh" "$WORK/bad-score.tsv" >/dev/null 2>&1; then
    echo "FAIL: evaluator accepted out-of-range score" >&2
    exit 1
fi
echo "  PASS  out-of-range score rejected"

echo "contract: m3-which-languages-suit-agentic-coding OK"
