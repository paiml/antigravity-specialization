#!/bin/bash
# Validates GitHub Actions job components: runs-on, timeout-minutes, steps, and needs graph.

set -euo pipefail

usage() {
    echo "Usage: $0 <workflow.yml> | --self-test" >&2
    exit 2
}

inspect_jobs() {
    local wf="$1"
    [ -f "$wf" ] || { echo "FAIL: workflow not found: $wf" >&2; return 1; }
    [ -s "$wf" ] || { echo "FAIL: workflow is empty: $wf" >&2; return 1; }

    awk '
    BEGIN { in_jobs=0; cur=""; n_jobs=0; err=0 }
    /^[^[:space:]#]/ {
        if ($0 ~ /^jobs:/) in_jobs=1; else in_jobs=0;
        next
    }
    !in_jobs { next }
    /^  [A-Za-z0-9_-]+:/ {
        cur=$1
        sub(/:$/, "", cur)
        order[++n_jobs]=cur
        exists[cur]=1
        steps[cur]=0
        needs[cur]=""
        runner[cur]=""
        timeout[cur]=""
        next
    }
    cur == "" { next }
    /^    runs-on:/ {
        val=$0; sub(/^    runs-on:[[:space:]]*/, "", val)
        runner[cur]=val
    }
    /^    timeout-minutes:/ {
        val=$0; sub(/^    timeout-minutes:[[:space:]]*/, "", val)
        timeout[cur]=val
    }
    /^    needs:/ {
        val=$0; sub(/^    needs:[[:space:]]*/, "", val)
        gsub(/[][ ]/, "", val)
        needs[cur]=val
    }
    /^      - / {
        steps[cur]++
    }
    END {
        if (n_jobs == 0) {
            print "FAIL: no jobs found under jobs:" > "/dev/stderr"
            exit 1
        }
        printf "%-12s %-15s %-8s %-15s %s\n", "JOB", "RUNS-ON", "TIMEOUT", "NEEDS", "STEPS"
        for (i=1; i<=n_jobs; i++) {
            j=order[i]
            if (runner[j] == "") {
                printf "FAIL: job \"%s\" missing runs-on\n", j > "/dev/stderr"
                err=1
            }
            if (timeout[j] !~ /^[0-9]+$/ || timeout[j] + 0 <= 0) {
                printf "FAIL: job \"%s\" missing positive timeout-minutes\n", j > "/dev/stderr"
                err=1
            }
            if (steps[j] == 0) {
                printf "FAIL: job \"%s\" has 0 steps\n", j > "/dev/stderr"
                err=1
            }
            if (needs[j] != "") {
                m=split(needs[j], deps, ",")
                for (k=1; k<=m; k++) {
                    d=deps[k]
                    if (d == j || !exists[d]) {
                        printf "FAIL: job \"%s\" has invalid needs target \"%s\"\n", j, d > "/dev/stderr"
                        err=1
                    }
                }
            }
            n_disp=(needs[j] == "" ? "-" : needs[j])
            printf "%-12s %-15s %-8s %-15s %d\n", j, runner[j], timeout[j], n_disp, steps[j]
        }
        if (err) exit 1
    }
    ' "$wf"
}

self_test() {
    local tmp
    tmp="$(mktemp -d)"

    : > "$tmp/empty.yml"
    if inspect_jobs "$tmp/empty.yml" >/dev/null 2>&1; then
        echo "SELF-TEST FAIL: empty workflow accepted" >&2
        rm -rf "$tmp"
        return 1
    fi

    cat > "$tmp/no-timeout.yml" <<'EOF'
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: echo hi
EOF
    if inspect_jobs "$tmp/no-timeout.yml" >/dev/null 2>&1; then
        echo "SELF-TEST FAIL: job without timeout-minutes accepted" >&2
        rm -rf "$tmp"
        return 1
    fi

    rm -rf "$tmp"
    echo "SELF-TEST OK"
    return 0
}

[ $# -eq 1 ] || usage
if [ "$1" = "--self-test" ]; then
    self_test
else
    inspect_jobs "$1"
fi
