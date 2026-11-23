#!/usr/bin/env bash
set -uo pipefail
. "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
# 3.1 A spec the agent cannot misread: every rule has an example and a test tag.
banner "spec-lint on a project that has the R5 tests"
d=$(new_work spec)
stage_into "$d" n-red
"$ROOT/scripts/spec-lint.sh" "$d" || LESSON_STATUS=FAILED
banner "spec-lint on a project with no tests yet: must fail"
e=$(new_work nospec)
stage_into "$e" spec-only
if "$ROOT/scripts/spec-lint.sh" "$e"; then LESSON_STATUS=FAILED; else echo "rejected, as intended"; fi
finish
