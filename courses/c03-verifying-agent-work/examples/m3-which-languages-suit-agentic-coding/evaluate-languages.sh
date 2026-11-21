#!/bin/bash
# Validates a language verification rubric TSV and classifies each row.
# Refuses empty, malformed, or out-of-range tables.

set -euo pipefail

TSV_FILE="${1:-}"
if [ -z "$TSV_FILE" ] || [ ! -s "$TSV_FILE" ]; then
    echo "FAIL: missing or empty rubric file: ${TSV_FILE:-<none>}" >&2
    exit 1
fi

awk -F'\t' '
NR == 1 {
    if ($0 != "language\tstatic_types\tfail_fast_errors\tdeterministic_tooling\tfast_gate_cli") {
        print "FAIL: invalid TSV header" > "/dev/stderr"
        exit 1
    }
    next
}
/^[[:space:]]*$/ { next }
{
    if (NF != 5 || $1 == "") {
        print "FAIL: malformed row at line " NR > "/dev/stderr"
        exit 1
    }
    for (i = 2; i <= 5; i++) {
        if ($i !~ /^[0-3]$/) {
            print "FAIL: score out of range (0-3) at line " NR " col " i > "/dev/stderr"
            exit 1
        }
    }
    rows++
    total = $2 + $3 + $4 + $5
    verdict = (total >= 8 && $3 >= 2) ? "SUITABLE" : "UNSAFE_WITHOUT_GATES"
    printf "%s\t%d\t%s\n", $1, total, verdict
}
END {
    if (rows == 0) {
        print "FAIL: anti-vacuity — zero language rows in rubric" > "/dev/stderr"
        exit 1
    }
}
' "$TSV_FILE"
