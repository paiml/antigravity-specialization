#!/usr/bin/env bash
set -uo pipefail
. "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
# 2.3 Refactor under green: same tests, still green.
agent_lesson n-green refactor-under-green.md green n-refactor n-green
finish
