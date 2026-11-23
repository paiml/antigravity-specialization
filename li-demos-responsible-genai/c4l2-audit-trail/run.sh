#!/usr/bin/env bash
# Lesson 4.2: a human approves each answer; every decision lands in a hash-chained audit log. Then we tamper and detect it.
# Decisions come from stdin (y/n per question). Try: c4l2-audit-trail/run.sh < c4l2-audit-trail/data/decisions.txt
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
need_server
mkdir -p "$here/out"
log="$here/out/audit.jsonl"
: >"$log"
while IFS= read -r q; do
  [ -z "$q" ] && continue
  ans=$(ask "Answer in one sentence." "$q" 48)
  echo "Q: $q"
  echo "A: $ans"
  IFS= read -r decision <&3 || decision=n
  case "$decision" in
    y) verdict=approved ;;
    *) verdict=rejected ;;
  esac
  echo "human: $verdict"
  audit_append "$log" "$(jq -nc --arg q "$q" --arg v "$verdict" '{q:$q,verdict:$v}')"
done 3<&0 <"$here/data/questions.txt"
echo "=== verify"
audit_verify "$log"
echo "=== rewrite line 1 in a copy, verify again"
sed '1s/.*/{"event":"{\\"q\\":\\"edited\\",\\"verdict\\":\\"approved\\"}","prev":"GENESIS"}/' "$log" >"$here/out/tampered.jsonl"
audit_verify "$here/out/tampered.jsonl" || echo "tampering detected"
