#!/usr/bin/env bash
# Lesson 2.3: summarize a local file; the text never leaves the machine.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
need_server
ask "Summarize the document in at most three bullet points." "$(cat "$here/data/memo.txt")" 120
