#!/usr/bin/env bash
# Lesson 3.6: guardrails as code. Refuse, filter, log. Each prompt line in data/prompts.txt goes through guard().
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
need_server
log="$here/guard.log.jsonl"
: >"$log"

# guard PROMPT -> prints the answer or a refusal; always appends one log line (with the prompt redacted).
guard() {
  local p="$1" shown action reply
  shown=$(printf '%s' "$p" | redact)
  if printf '%s' "$p" | grep -Eiq 'build a (bomb|weapon)|make (malware|ransomware)|steal (a )?password'; then
    action=refused-topic
    echo "REFUSED (blocked topic)"
  elif [ "$(sensitivity "$p")" = high ]; then
    action=refused-sensitive
    echo "REFUSED (sensitive data in prompt: remove it and retry)"
  else
    reply=$(ask "Answer in at most two sentences." "$p" 70 | redact)
    action=answered
    echo "$reply"
  fi
  jq -nc --arg a "$action" --arg p "$shown" '{action:$a,prompt:$p}' >>"$log"
}

while IFS= read -r line; do
  [ -z "$line" ] && continue
  echo "> $line"
  guard "$line"
  echo
done <"$here/data/prompts.txt"
echo "=== log"
cat "$log"
