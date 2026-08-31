#!/bin/bash
# Rung zero -- be interviewed before anything is planned or built.
#
# /grill-me walks the design tree one question at a time and attaches its own
# recommended answer to each, so you are approving or overriding rather than
# being interrogated. It is told that if a question can be answered by reading
# the codebase, it must go read instead of asking you -- so the questions you
# actually get are the ones the repository genuinely cannot settle.
#
# Not -p. An interview needs the session to stay open, so this uses -i
# (--prompt-interactive): run the first prompt, then keep going.

set -euo pipefail

command -v agy >/dev/null 2>&1 || {
    echo "error: 'agy' not found. Install the Antigravity CLI first." >&2
    exit 127
}

TASK="${*:-add a transpose step to remove_star.sh}"

agy -i "/grill-me $TASK"
