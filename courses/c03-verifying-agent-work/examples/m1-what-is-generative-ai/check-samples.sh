#!/bin/bash
# Enforces deterministic artifact invariants against stochastic LLM drift.
# Usage:
#   ./check-samples.sh            (demonstrates valid pass + drifted reject)
#   ./check-samples.sh <file>     (exits 0 iff <file> satisfies all invariants)

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"

validate_file() {
    local target="$1"
    local errors=0

    if [ ! -f "$target" ]; then
        echo "error: file not found: $target" >&2
        return 1
    fi

    if [ ! -s "$target" ]; then
        echo "error: artifact is empty: $target" >&2
        return 1
    fi

    local header
    header="$(head -n 1 "$target")"
    if [ "$header" != "# CONTRACT v1" ]; then
        echo "error: missing exact header '# CONTRACT v1', got [$header]" >&2
        errors=$((errors + 1))
    fi

    local stray_lines
    stray_lines="$(awk 'NR > 1 && $0 !~ /^[A-Z0-9_]+=.+$/ { count++ } END { print count + 0 }' "$target")"
    if [ "$stray_lines" -ne 0 ]; then
        echo "error: found $stray_lines non-contract/prose line(s)" >&2
        errors=$((errors + 1))
    fi

    local actual_lines
    actual_lines="$(wc -l < "$target" | tr -d ' ')"

    local declared_lines artifact hex_digest status
    artifact="$(awk -F= '$1 == "ARTIFACT" { print substr($0, 10) }' "$target" | head -n 1)"
    declared_lines="$(awk -F= '$1 == "LINE_COUNT" { print substr($0, 12) }' "$target" | head -n 1)"
    hex_digest="$(awk -F= '$1 == "HEX_DIGEST" { print substr($0, 12) }' "$target" | head -n 1)"
    status="$(awk -F= '$1 == "STATUS" { print substr($0, 8) }' "$target" | head -n 1)"

    if ! printf '%s' "$artifact" | grep -Eq '^[a-z0-9-]+$'; then
        echo "error: invalid ARTIFACT: [$artifact]" >&2
        errors=$((errors + 1))
    fi

    if [ "$declared_lines" != "$actual_lines" ]; then
        echo "error: LINE_COUNT=[$declared_lines] does not match actual lines [$actual_lines]" >&2
        errors=$((errors + 1))
    fi

    if ! printf '%s' "$hex_digest" | grep -Eq '^[0-9a-f]{64}$'; then
        echo "error: HEX_DIGEST must be 64 lowercase hex chars, got [$hex_digest]" >&2
        errors=$((errors + 1))
    fi

    if [ "$status" != "verified" ]; then
        echo "error: STATUS must be 'verified', got [$status]" >&2
        errors=$((errors + 1))
    fi

    [ "$errors" -eq 0 ]
}

if [ "$#" -gt 0 ]; then
    validate_file "$1"
    echo "PASS: $1 satisfies deterministic invariants"
    exit 0
fi

echo "Checking compliant artifact..."
validate_file "$HERE/samples/candidate-valid.txt"
echo "  PASS  samples/candidate-valid.txt"

echo "Checking stochastically drifted artifact..."
if validate_file "$HERE/samples/candidate-drifted.txt" 2>/dev/null; then
    echo "  FAIL  drifted artifact unexpectedly passed" >&2
    exit 1
else
    echo "  PASS  samples/candidate-drifted.txt was rejected as expected"
fi
