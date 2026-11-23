#!/usr/bin/env bash
set -uo pipefail
. "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
# 2.2 Make it pass, and only that: green, and the tests are byte-for-byte what you approved.
agent_lesson n-red make-it-pass.md green n-green n-red
finish
