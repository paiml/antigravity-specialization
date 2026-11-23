#!/usr/bin/env bash
# agy-replay.sh: a stand-in for the agy CLI that replays a committed reference reply. It is NOT an agent.
# agy_step calls it as: agy-replay.sh --print=<prompt text> --mode <m> --print-timeout <t>
# It finds the lesson whose prompts/*.md holds exactly that text, then prints lessons/replay/<lesson>.txt.
# An unknown prompt prints one error line and exits 2. `--version` prints AGY_PIN.
set -uo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
AGY_PIN="${AGY_PIN:-1.5.10}"
prompt=""
have_prompt=0
for a in "$@"; do
  case "$a" in
    --version)
      echo "$AGY_PIN"
      exit 0
      ;;
    --print=*)
      prompt="${a#--print=}"
      have_prompt=1
      ;;
  esac
done
if [ "$have_prompt" -eq 0 ]; then
  echo "agy-replay: no --print prompt" >&2
  exit 2
fi
for f in "$root"/*/prompts/*.md; do
  [ -f "$f" ] || continue
  if [ "$(<"$f")" = "$prompt" ]; then
    lesson="$(basename "$(dirname "$(dirname "$f")")")"
    reply="$root/lessons/replay/$lesson.txt"
    if [ ! -f "$reply" ]; then
      echo "agy-replay: no reply file for $lesson" >&2
      exit 2
    fi
    echo "REPLAY: reference reply, NOT live agent output"
    printf '%s\n' "$(<"$reply")"
    exit 0
  fi
done
echo "agy-replay: unknown prompt" >&2
exit 2
