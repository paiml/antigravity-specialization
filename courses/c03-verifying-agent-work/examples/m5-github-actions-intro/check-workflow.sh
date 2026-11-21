#!/bin/bash
# Offline validator for GitHub Actions workflow YAML using bash and awk only.

set -euo pipefail

usage() {
    echo "Usage: $0 <workflow.yml> [repo-root] | --self-test" >&2
    exit 2
}

validate_workflow() {
    local wf="$1"
    local repo_root="${2:-}"
    local tab_lines key unpinned script_ref

    [ -f "$wf" ] || { echo "FAIL: workflow not found: $wf" >&2; return 1; }
    [ -s "$wf" ] || { echo "FAIL: workflow is empty: $wf" >&2; return 1; }

    if [ -z "$repo_root" ]; then
        repo_root="$(cd "$(dirname "$wf")/../.." && pwd)"
    fi

    tab_lines="$(awk '/\t/{print NR}' "$wf")"
    if [ -n "$tab_lines" ]; then
        echo "FAIL: YAML forbids tabs for indentation (lines: $tab_lines)" >&2
        return 1
    fi

    for key in name on permissions jobs; do
        if ! grep -qE "^${key}:" "$wf"; then
            echo "FAIL: missing required top-level key: ${key}:" >&2
            return 1
        fi
    done

    if ! awk '
        BEGIN { in_jobs=0; jobs=0; has_runner=0; has_steps=0; step_items=0 }
        /^[^[:space:]#]/ {
            if ($0 ~ /^jobs:/) in_jobs=1; else in_jobs=0;
            next
        }
        in_jobs && /^  [A-Za-z0-9_-]+:/ { jobs++ }
        in_jobs && /^    runs-on:/ { has_runner++ }
        in_jobs && /^    steps:/ { has_steps++ }
        in_jobs && /^      - / { step_items++ }
        END {
            if (jobs == 0 || has_runner < jobs || has_steps < jobs || step_items == 0) exit 1
        }
    ' "$wf"; then
        echo "FAIL: jobs section must define at least one job with runs-on, steps, and step items" >&2
        return 1
    fi

    unpinned="$(awk '
        /^[[:space:]]*(-[[:space:]]*)?uses:/ {
            line=$0
            sub(/^[[:space:]]*(-[[:space:]]*)?uses:[[:space:]]*/, "", line)
            gsub(/["'\'' ]/, "", line)
            if (line !~ /@(v[0-9]+(\.[0-9]+)*|[0-9a-f]{40})$/) {
                print NR ": " line
            }
        }
    ' "$wf")"
    if [ -n "$unpinned" ]; then
        echo "FAIL: unpinned action reference(s) (must pin @vN or 40-char SHA):" >&2
        printf '%s\n' "$unpinned" >&2
        return 1
    fi

    while IFS= read -r script_ref; do
        [ -z "$script_ref" ] && continue
        if [ ! -s "$repo_root/$script_ref" ]; then
            echo "FAIL: workflow references missing or empty script: $script_ref" >&2
            return 1
        fi
    done < <(awk '
        /run:/ {
            for (i=1; i<=NF; i++) {
                if ($i ~ /^\.?\/?scripts\/[A-Za-z0-9._\/-]+\.sh$/) {
                    s=$i
                    sub(/^\.\//, "", s)
                    print s
                }
            }
        }
    ' "$wf")

    echo "WORKFLOW PASS: $wf"
    return 0
}

self_test() {
    local tmp
    tmp="$(mktemp -d)"

    : > "$tmp/empty.yml"
    if validate_workflow "$tmp/empty.yml" "$tmp" >/dev/null 2>&1; then
        echo "SELF-TEST FAIL: empty workflow accepted" >&2
        rm -rf "$tmp"
        return 1
    fi

    cat > "$tmp/unpinned.yml" <<'EOF'
name: Bad
on: push
permissions:
  contents: read
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@main
      - run: echo ok
EOF
    if validate_workflow "$tmp/unpinned.yml" "$tmp" >/dev/null 2>&1; then
        echo "SELF-TEST FAIL: unpinned @main action accepted" >&2
        rm -rf "$tmp"
        return 1
    fi

    rm -rf "$tmp"
    echo "SELF-TEST OK"
    return 0
}

[ $# -ge 1 ] || usage
if [ "$1" = "--self-test" ]; then
    self_test
else
    validate_workflow "$1" "${2:-}"
fi
