#!/bin/bash
# Verify audit-agent-run.sh passes on good-run and rejects all four failure modes.

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

AUDITOR="$HERE/audit-agent-run.sh"

# 1. Clean run must pass.
bash "$AUDITOR" "$HERE/fixtures/good-run" "out/report.txt" "work" >/dev/null
echo "  PASS  good-run accepted"

# 2. Each failure fixture must be rejected.
for name in fail-empty-output fail-swallowed-pipe fail-scope-drift fail-contradictory-log; do
    if bash "$AUDITOR" "$HERE/fixtures/$name" "out/report.txt" "work" >/dev/null 2>&1; then
        echo "  FAIL  auditor accepted $name" >&2
        exit 1
    fi
    echo "  PASS  $name rejected"
done

# 3. Empty workspace must be rejected.
mkdir -p "$WORK/empty"
if bash "$AUDITOR" "$WORK/empty" "out/report.txt" "work" >/dev/null 2>&1; then
    echo "  FAIL  auditor accepted empty workspace" >&2
    exit 1
fi
echo "  PASS  empty workspace rejected"

echo "contract: m3-when-agents-fail OK"
