#!/bin/bash
# Verifies job inspection, execution order, and failure propagation.

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if [ "${1:-}" = "--self-test" ]; then
    bash "$HERE/inspect-jobs.sh" --self-test
    exit 0
fi

echo "1. Self-testing inspect-jobs.sh..."
bash "$HERE/inspect-jobs.sh" --self-test

echo "2. Inspecting pipeline.yml job components..."
INSPECT_OUT="$(bash "$HERE/inspect-jobs.sh" "$HERE/.github/workflows/pipeline.yml")"
printf '%s\n' "$INSPECT_OUT"
JOB_COUNT="$(printf '%s\n' "$INSPECT_OUT" | awk 'NR>1{c++} END{print c+0}')"
[ "$JOB_COUNT" -eq 3 ] || { echo "FAIL: expected 3 jobs, got $JOB_COUNT" >&2; exit 1; }

echo "3. Running clean pipeline..."
bash "$HERE/run-job.sh" "$HERE/.github/workflows/pipeline.yml" "$HERE"

echo "4. Verifying bad needs target is rejected..."
cat > "$WORK/bad-needs.yml" <<'EOF'
jobs:
  test:
    needs: missing_job
    runs-on: ubuntu-latest
    timeout-minutes: 5
    steps:
      - run: echo test
EOF
set +e
bash "$HERE/inspect-jobs.sh" "$WORK/bad-needs.yml" >/dev/null 2>&1
NEEDS_EC=$?
set -e
[ "$NEEDS_EC" -ne 0 ] || { echo "FAIL: unknown needs target was accepted" >&2; exit 1; }

echo "5. Verifying lint failure stops downstream test job..."
mkdir -p "$WORK/broken-repo/scripts"
cat > "$WORK/broken-repo/scripts/app.sh" <<'EOF'
#!/bin/bash
if [ true
EOF
set +e
FAIL_OUT="$(bash "$HERE/run-job.sh" "$HERE/.github/workflows/pipeline.yml" "$WORK/broken-repo" 2>&1)"
FAIL_EC=$?
set -e
[ "$FAIL_EC" -ne 0 ] || { echo "FAIL: broken syntax passed run-job.sh" >&2; exit 1; }
if printf '%s\n' "$FAIL_OUT" | grep -q '^\[job: test\]'; then
    echo "FAIL: downstream test job ran despite lint failure" >&2
    exit 1
fi

echo "contract: m5-components-of-a-job OK"
