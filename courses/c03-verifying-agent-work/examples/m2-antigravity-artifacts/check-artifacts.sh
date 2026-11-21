#!/bin/bash
# Validates Antigravity control artifacts (implementation_plan.md, task.md, walkthrough.md).
# Usage: ./check-artifacts.sh [artifact_dir]

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
DIR="${1:-$HERE}"

if [ ! -d "$DIR" ]; then
    echo "error: directory not found: $DIR" >&2
    exit 1
fi

PLAN="$DIR/implementation_plan.md"
TASK="$DIR/task.md"
WALK="$DIR/walkthrough.md"

errors=0

for f in "$PLAN" "$TASK" "$WALK"; do
    if [ ! -f "$f" ] || [ ! -s "$f" ]; then
        echo "FAIL: artifact missing or empty: $f" >&2
        errors=$((errors + 1))
    fi
done

if [ -s "$PLAN" ]; then
    for heading in "## User Review Required" "## Proposed Changes" "## Verification Plan"; do
        if ! grep -Fq "$heading" "$PLAN"; then
            echo "FAIL: implementation_plan.md missing section '$heading'" >&2
            errors=$((errors + 1))
        fi
    done
fi

if [ -s "$TASK" ]; then
    if ! grep -Eq '^- \[(x| )\] ' "$TASK"; then
        echo "FAIL: task.md contains no markdown checklist items" >&2
        errors=$((errors + 1))
    fi
fi

if [ -s "$WALK" ]; then
    if ! grep -Fq "## Verification Results" "$WALK"; then
        echo "FAIL: walkthrough.md missing section '## Verification Results'" >&2
        errors=$((errors + 1))
    fi
    if grep -Eq '(TODO|TBD|FIXME)' "$WALK"; then
        echo "FAIL: walkthrough.md contains unresolved placeholder (TODO/TBD/FIXME)" >&2
        errors=$((errors + 1))
    fi
fi

if [ "$errors" -ne 0 ]; then
    echo "Artifact check failed with $errors error(s)." >&2
    exit 1
fi

echo "Artifacts verified in $DIR"
