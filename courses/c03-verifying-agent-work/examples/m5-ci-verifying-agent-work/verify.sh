#!/bin/bash
# Verifies sample-pr passes and 4 agent failure modes are rejected.

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if [ "${1:-}" = "--self-test" ]; then
    bash "$HERE/verify-agent-pr.sh" --self-test
    exit 0
fi

assert_fails() {
    local label="$1"
    local dir="$2"
    local ec
    set +e
    bash "$HERE/verify-agent-pr.sh" "$dir" >/dev/null 2>&1
    ec=$?
    set -e
    if [ "$ec" -eq 0 ]; then
        echo "FAIL: $label unexpectedly passed" >&2
        exit 1
    fi
    echo "  PASS (rejected): $label"
}

echo "1. Self-testing verify-agent-pr.sh..."
bash "$HERE/verify-agent-pr.sh" --self-test

echo "2. Verifying clean sample-pr passes..."
bash "$HERE/verify-agent-pr.sh" "$HERE/sample-pr"

echo "3. Testing 4 agent failure modes..."
mkdir -p "$WORK/empty-pr"
assert_fails "empty PR directory" "$WORK/empty-pr"

cp -r "$HERE/sample-pr" "$WORK/scope-pr"
mkdir -p "$WORK/scope-pr/.github/workflows"
printf 'name: modified\n' > "$WORK/scope-pr/.github/workflows/ci.yml"
printf '.github/workflows/ci.yml\n' >> "$WORK/scope-pr/changed-files.txt"
assert_fails "out-of-scope workflow edit" "$WORK/scope-pr"

cp -r "$HERE/sample-pr" "$WORK/todo-pr"
printf '# TODO: handle binary input\n' >> "$WORK/todo-pr/src/transform.sh"
assert_fails "planted TODO in agent code" "$WORK/todo-pr"

cp -r "$HERE/sample-pr" "$WORK/weak-pr"
cat > "$WORK/weak-pr/tests/run_tests.sh" <<'EOF'
#!/bin/bash
set -euo pipefail
# PASS: disabled second assertion to make PR green
echo "PASS: only one assertion left"
EOF
assert_fails "weakened/commented-out test assertion" "$WORK/weak-pr"

echo "contract: m5-ci-verifying-agent-work OK"
