#!/usr/bin/env bash
# 100% line coverage of the demo code path, per module.
#   scripts/coverage.sh            every module present
#   scripts/coverage.sh m1 m3      just those modules
# Checks for cargo-llvm-cov; installs nothing.
set -euo pipefail
cd "$(dirname "$0")/.."
cargo llvm-cov --version >/dev/null || { echo "coverage: cargo-llvm-cov missing" >&2; exit 1; }
if [ "$#" -gt 0 ]; then mods=("$@"); else mods=(); for d in m*/Cargo.toml; do [ -e "$d" ] && mods+=("${d%/Cargo.toml}"); done; fi
[ "${#mods[@]}" -gt 0 ] || { echo "coverage: no module found" >&2; exit 1; }
for m in "${mods[@]}"; do
  echo "== coverage $m"
  ( cd "$m" && cargo llvm-cov --locked --fail-under-lines 100 --summary-only )
done
echo "coverage: OK (${#mods[@]} modules, 100% lines each)"
