#!/usr/bin/env bash
set -uo pipefail
. "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
# 2.1 Ask for a failing test first: the check is "red, and only the tests changed".
agent_lesson green failing-test-first.md red n-red green
finish
