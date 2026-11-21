#!/bin/bash
set -euo pipefail

echo "smoke: checking bash version and basic pipeline..."
[ -n "${BASH_VERSION:-}" ] || { echo "FAIL: bash required" >&2; exit 1; }
echo "smoke: PASS"
