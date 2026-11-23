#!/usr/bin/env bash
set -uo pipefail
. "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
# 3.4 Mutation testing: break the code on purpose and see whether the tests notice.
banner "weak suite: base examples only"
"$ROOT/scripts/mutate.sh" n-green "$ROOT/stages/green/tests/cases.txt" && echo "(unexpected: weak suite killed everything)" || echo "=> survivors found: the weak suite misses bugs"
banner "full suite: base plus R5 examples"
"$ROOT/scripts/mutate.sh" n-green "$ROOT/stages/n-green/tests/cases.txt" || LESSON_STATUS=FAILED
finish
