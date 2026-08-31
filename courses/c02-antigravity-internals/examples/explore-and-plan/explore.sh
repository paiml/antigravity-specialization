#!/bin/bash
# Rung 1 -- explore. Ask what the repository already does, before changing it.
#
# --mode plan is what makes this safe, not -p. -p (--print) only means "one
# turn, print the answer"; it restricts no tools. --mode plan is the flag that
# stops the agent writing. Passing both gives you one non-interactive answer
# and a guarantee that your working tree is untouched.

set -euo pipefail

command -v agy >/dev/null 2>&1 || {
    echo "error: 'agy' not found. Install the Antigravity CLI first." >&2
    exit 127
}

agy -p 'Explain what this repository is for, how the courses and examples are laid out, and what enforces that layout. Do not change anything.' --mode plan
