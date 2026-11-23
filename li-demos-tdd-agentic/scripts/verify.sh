#!/usr/bin/env bash
# verify.sh DIR MODE PIN_STAGE: check an agent's work against the tests.
#   red     tests must FAIL and src must equal PIN_STAGE's src (only tests changed)
#   green   tests must pass and tests must equal PIN_STAGE's tests (the agent did not edit them)
#   spec    every rule id in the spec must be tagged in the tests, and src must equal PIN_STAGE's src
set -uo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
. "$here/lib/common.sh"
dir="$1"
mode="$2"
pin="$3"
case "$mode" in
  red)
    if ! cmp -s "$dir/src/slugify.sh" "$here/stages/$pin/src/slugify.sh"; then
      echo "FAIL: the red step changed src/slugify.sh"
      exit 1
    fi
    if run_tests "$dir" >/dev/null; then
      echo "FAIL: the new tests are not red"
      exit 1
    fi
    echo "RED ok: tests fail, src untouched"
    ;;
  green)
    if ! cmp -s "$dir/tests/cases.txt" "$here/stages/$pin/tests/cases.txt"; then
      echo "CHEAT: tests/cases.txt was edited"
      exit 1
    fi
    if ! run_tests "$dir" >/dev/null; then
      echo "FAIL: tests are red"
      exit 1
    fi
    echo "GREEN ok: tests pass, tests untouched"
    ;;
  spec)
    if ! cmp -s "$dir/src/slugify.sh" "$here/stages/$pin/src/slugify.sh"; then
      echo "FAIL: src changed while writing tests"
      exit 1
    fi
    "$here/scripts/spec-lint.sh" "$dir"
    ;;
  *)
    echo "usage: verify.sh DIR red|green|spec PIN_STAGE" >&2
    exit 2
    ;;
esac
