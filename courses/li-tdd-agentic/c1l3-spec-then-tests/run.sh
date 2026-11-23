#!/usr/bin/env bash
set -uo pipefail
. "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
# 1.3 The agent writes the tests, you approve the spec: the approval is a mechanical check.
agent_lesson spec-only write-tests-from-spec.md spec tests-written stub
finish
