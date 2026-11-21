#!/bin/bash
# Contrasts permissive bash vs strict bash (set -euo pipefail) on the same bug.
# Prints "PERMISSIVE_RC=<n>" and "STRICT_RC=<n>" and exits 0 only when
# permissive silently succeeds (0) while strict fails non-zero.

set -euo pipefail

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cat > "$WORK/buggy_body.sh" <<'EOF'
PREFIX="expected"
# Bug 1: unset variable typo writes to "_out.txt" instead of "expected_out.txt"
printf 'data\n' > "${PREFX}_out.txt"
# Bug 2: upstream command fails inside a pipeline
false | awk '{print "ok"}'
EOF

set +e
(cd "$WORK" && bash buggy_body.sh >/dev/null 2>&1)
PERM_RC=$?
(cd "$WORK" && bash -euo pipefail buggy_body.sh >/dev/null 2>&1)
STRICT_RC=$?
set -e

echo "PERMISSIVE_RC=$PERM_RC"
echo "STRICT_RC=$STRICT_RC"

if [ "$PERM_RC" -ne 0 ]; then
    echo "FAIL: expected permissive mode to mask the bug (rc=0), got rc=$PERM_RC" >&2
    exit 1
fi
if [ "$STRICT_RC" -eq 0 ]; then
    echo "FAIL: expected strict mode to catch the bug (rc!=0), got rc=0" >&2
    exit 1
fi
