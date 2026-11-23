#!/usr/bin/env bash
# Lesson 4.3: route by sensitivity. High-sensitivity prompts stay on the local model; low ones MAY go to a hosted model.
# The hosted side is a stub here: this demo makes no network call and holds no credentials.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
need_server

hosted_stub() {
  echo "[hosted route: would send this prompt to the hosted API; NOT called in this demo]"
}

while IFS= read -r p; do
  [ -z "$p" ] && continue
  level=$(sensitivity "$p")
  echo "> $p"
  echo "sensitivity: $level"
  if [ "$level" = high ]; then
    echo "route: LOCAL"
    ask "Answer in one sentence." "$(printf '%s' "$p" | redact)" 60
  else
    echo "route: HOSTED"
    hosted_stub
  fi
  echo
done <"$here/data/prompts.txt"
