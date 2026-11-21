#!/bin/bash
set -euo pipefail

GOT1="$(printf '  hello world  \n' | bash ./src/transform.sh)"
[ "$GOT1" = "HELLO WORLD" ] || { echo "FAIL: expected HELLO WORLD, got [$GOT1]" >&2; exit 1; }
echo "PASS: trims and uppercases input"

GOT2="$(printf 'agent_ci_42\n' | bash ./src/transform.sh)"
[ "$GOT2" = "AGENT_CI_42" ] || { echo "FAIL: expected AGENT_CI_42, got [$GOT2]" >&2; exit 1; }
echo "PASS: preserves underscores and digits"
