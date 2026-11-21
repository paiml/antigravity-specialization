#!/bin/bash
# TDD specification suite for slugify implementations.
# Usage: bash test_slugify.sh <path-to-slugify-script>

set -euo pipefail

IMPL="${1:-}"
if [ -z "$IMPL" ] || [ ! -s "$IMPL" ]; then
    echo "FAIL: missing or empty implementation script: ${IMPL:-<none>}" >&2
    exit 1
fi

failed=0
cases=0

assert_slug() {
    local input="$1"
    local want="$2"
    local got rc
    cases=$((cases + 1))
    set +e
    got="$(bash "$IMPL" "$input" 2>/dev/null)"
    rc=$?
    set -e
    if [ "$rc" -ne 0 ] || [ "$got" != "$want" ]; then
        echo "  FAIL  input=[$input] expected=[$want] rc=0, got=[$got] rc=$rc" >&2
        failed=$((failed + 1))
    fi
}

assert_rejects() {
    local input="$1"
    cases=$((cases + 1))
    if bash "$IMPL" "$input" >/dev/null 2>&1; then
        echo "  FAIL  input=[$input] expected non-zero exit, got rc=0" >&2
        failed=$((failed + 1))
    fi
}

assert_slug "Using Test-Driven Development" "using-test-driven-development"
assert_slug "Which Languages Suit Agentic Coding?" "which-languages-suit-agentic-coding"
assert_slug "  Spaces   and -- Dashes!  " "spaces-and-dashes"
assert_slug "PMAT v2.0" "pmat-v2-0"
assert_rejects ""
assert_rejects "???"

if [ "$cases" -lt 6 ] || [ "$failed" -ne 0 ]; then
    echo "TDD suite failed: $failed of $cases case(s) failed." >&2
    exit 1
fi

echo "TDD suite passed: $cases of $cases cases."
