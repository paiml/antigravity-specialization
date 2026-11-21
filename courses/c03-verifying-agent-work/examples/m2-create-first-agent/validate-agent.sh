#!/bin/bash
# Validates an Antigravity agent markdown file offline (frontmatter + persona body).
# Usage: ./validate-agent.sh <agent.md>

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
AGENT_FILE="${1:-$HERE/agents/verify-first.md}"

if [ ! -f "$AGENT_FILE" ] || [ ! -s "$AGENT_FILE" ]; then
    echo "FAIL: agent file missing or empty: $AGENT_FILE" >&2
    exit 1
fi

awk '
NR == 1 {
    if ($0 != "---") {
        print "FAIL: line 1 must be ---" > "/dev/stderr"
        bad = 1
        exit 1
    }
    in_fm = 1
    next
}
in_fm == 1 && $0 == "---" {
    in_fm = 0
    close_line = NR
    next
}
in_fm == 1 {
    if ($0 ~ /^name:[[:space:]]*[a-zA-Z0-9_-]+[[:space:]]*$/) has_name = 1
    if ($0 ~ /^description:[[:space:]]*[^[:space:]].+$/) has_desc = 1
    next
}
$0 ~ /[^[:space:]]/ {
    body_lines++
}
END {
    if (bad) exit 1
    if (close_line == 0) {
        print "FAIL: missing closing --- frontmatter delimiter" > "/dev/stderr"
        exit 1
    }
    if (!has_name) {
        print "FAIL: missing or invalid frontmatter name:" > "/dev/stderr"
        exit 1
    }
    if (!has_desc) {
        print "FAIL: missing frontmatter description:" > "/dev/stderr"
        exit 1
    }
    if (body_lines < 1) {
        print "FAIL: agent persona body is empty" > "/dev/stderr"
        exit 1
    }
}
' "$AGENT_FILE"

echo "Agent definition valid: $AGENT_FILE"
