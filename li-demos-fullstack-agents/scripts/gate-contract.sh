#!/usr/bin/env bash
# Validate every file in contracts/ with pv. Prints the count so "0 contracts" cannot pass.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
if ! command -v pv >/dev/null 2>&1; then
  echo "contract: SKIPPED, pv is not installed here (nothing was validated)"
  exit 0
fi
n=0
bad=0
for f in contracts/*.yaml; do
  [ -f "$f" ] || continue
  n=$((n + 1))
  if pv validate "$f" >/dev/null 2>&1; then
    echo "contract ok    $f"
  else
    echo "contract FAIL  $f"
    bad=1
  fi
done
echo "contract: $n files"
if [ "$n" -eq 0 ]; then
  echo "FAIL validated 0 contracts"
  exit 1
fi
if [ "$bad" -ne 0 ]; then exit 1; fi
echo "contract OK"
