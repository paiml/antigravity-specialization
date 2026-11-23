#!/usr/bin/env bash
# Lesson 2.5: ask for JSON, validate it with jq, retry once, never trust unchecked output.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
need_server
text="${1:-Maria Lopez, 34, joined the Madrid office as a data engineer.}"
prompt="Extract JSON with keys name (string), age (number), city (string), role (string) from the text. Output only JSON, no prose.

Text: $text"
validate() {
  jq -e 'type == "object" and (.name|type == "string") and (.age|type == "number") and (.city|type == "string") and (.role|type == "string")' >/dev/null 2>&1
}
for attempt in 1 2; do
  raw=$(ask "You output strict JSON only." "$prompt" 120)
  json=$(printf '%s' "$raw" | sed -e 's/^```json//' -e 's/^```//' -e 's/```$//')
  echo "attempt $attempt raw: $raw"
  if printf '%s' "$json" | validate; then
    echo "VALID"
    printf '%s' "$json" | jq -c .
    exit 0
  fi
  echo "INVALID: schema check failed"
done
echo "giving up after 2 attempts: no unvalidated output is used"
exit 1
