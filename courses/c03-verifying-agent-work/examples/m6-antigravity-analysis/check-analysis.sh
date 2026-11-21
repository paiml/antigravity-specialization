#!/bin/bash
# Offline ground-truth checker for an Antigravity analysis report.
# Verifies every cited file:line exists and is within bounds, and that all
# planted verification gaps in target-repo are reported.

set -euo pipefail

usage() {
    echo "Usage: $0 <target-repo> <analysis.md> | --self-test" >&2
    exit 2
}

check_analysis() {
    local repo="$1"
    local report="$2"
    local cite file line max_lines cite_count=0

    [ -d "$repo" ] || { echo "FAIL: target repo not found: $repo" >&2; return 1; }
    [ -s "$report" ] || { echo "FAIL: analysis report missing or empty: $report" >&2; return 1; }

    while IFS= read -r cite; do
        [ -z "$cite" ] && continue
        file="${cite%%:*}"
        line="${cite##*:}"
        file="${file#target-repo/}"

        if [ ! -f "$repo/$file" ]; then
            echo "FAIL [hallucinated file]: cited file does not exist: $file" >&2
            return 1
        fi
        max_lines="$(wc -l < "$repo/$file" | tr -d ' ')"
        if [ "$line" -lt 1 ] || [ "$line" -gt "$max_lines" ]; then
            echo "FAIL [bad line]: $file:$line out of range (1..$max_lines)" >&2
            return 1
        fi
        cite_count=$((cite_count + 1))
    done < <(awk '
        {
            s = $0
            while (match(s, /[A-Za-z0-9_.\/-]+\.(yml|yaml|sh|md):[0-9]+/)) {
                tok = substr(s, RSTART, RLENGTH)
                print tok
                s = substr(s, RSTART + RLENGTH)
            }
        }
    ' "$report")

    if [ "$cite_count" -lt 3 ]; then
        echo "FAIL [anti-vacuity]: expected >= 3 valid file:line citations, got $cite_count" >&2
        return 1
    fi

    grep -q '\.github/workflows/ci\.yml:' "$report" || { echo "FAIL: missing citation to .github/workflows/ci.yml" >&2; return 1; }
    grep -q '|| true' "$report" || { echo "FAIL: missing finding on || true exit-code swallowing" >&2; return 1; }
    grep -q '@main' "$report" || { echo "FAIL: missing finding on unpinned @main action" >&2; return 1; }
    grep -q 'scripts/process\.sh:' "$report" || { echo "FAIL: missing citation to scripts/process.sh" >&2; return 1; }
    grep -q 'set -euo pipefail' "$report" || { echo "FAIL: missing finding on missing set -euo pipefail" >&2; return 1; }
    grep -q 'tests/test_process\.sh:' "$report" || { echo "FAIL: missing citation to tests/test_process.sh" >&2; return 1; }

    echo "ANALYSIS PASS: $cite_count grounded citation(s) verified against $repo"
    return 0
}

self_test() {
    local tmp
    tmp="$(mktemp -d)"
    mkdir -p "$tmp/repo"
    printf 'one\ntwo\n' > "$tmp/repo/a.sh"
    : > "$tmp/empty.md"
    if check_analysis "$tmp/repo" "$tmp/empty.md" >/dev/null 2>&1; then
        echo "SELF-TEST FAIL: empty analysis report accepted" >&2
        rm -rf "$tmp"
        return 1
    fi
    printf 'See a.sh:99\n' > "$tmp/badline.md"
    if check_analysis "$tmp/repo" "$tmp/badline.md" >/dev/null 2>&1; then
        echo "SELF-TEST FAIL: out-of-range line citation accepted" >&2
        rm -rf "$tmp"
        return 1
    fi
    rm -rf "$tmp"
    echo "SELF-TEST OK"
    return 0
}

if [ "${1:-}" = "--self-test" ]; then
    self_test
elif [ $# -eq 2 ]; then
    check_analysis "$1" "$2"
else
    usage
fi
