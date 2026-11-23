#!/usr/bin/env bash
# Lesson 4.4: a responsible-AI checklist you can commit. This script checks the repo it lives in; no model needed.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="${CHECK_ROOT:-$(dirname "$here")}"
fail=0
# check DESCRIPTION COMMAND [ARGS...]: PASS when the command succeeds.
check() {
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then echo "PASS  $desc"; else echo "FAIL  $desc"; fail=1; fi
}
check "a LICENSE file exists" test -s "$root/LICENSE"
check "a README states what the model may not be used for" grep -qi 'not be used for' "$root/README.md"
check "secrets are scanned in CI (gitleaks config present)" test -s "$root/.gitleaks.toml"
check "prompts are redacted before logging (redact defined)" grep -q '^redact()' "$root/lib/common.sh"
check "model output is validated before use (jq -e in the JSON lesson)" grep -q 'jq -e' "$root/c2l5-json-validate/run.sh"
check "decisions are logged to an audit trail (audit_append defined)" grep -q '^audit_append()' "$root/lib/common.sh"
check "an evaluation set exists with a ship gate" test -s "$root/c4l1-eval-set/data/eval.jsonl"
if [ "$fail" -ne 0 ]; then echo "checklist FAILED"; exit 1; fi
echo "checklist passed"
