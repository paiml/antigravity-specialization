#!/usr/bin/env bash
# 100% line coverage of the demo code path, per module.
#   scripts/coverage.sh            every module present
#   scripts/coverage.sh m1 m3      just those modules
#   scripts/coverage.sh --self-test  feed its checks known-bad input, then plant each defect in a
#                                    copy of the course (scripts/self-test.sh): every one must be refused
# Checks for cargo-llvm-cov; installs nothing.
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck source=lib.sh
. scripts/lib.sh
if [ "${1-}" = --self-test ]; then self_test_lib && exec bash scripts/self-test.sh coverage; exit 1; fi
cargo llvm-cov --version >/dev/null || { echo "coverage: cargo-llvm-cov missing" >&2; exit 1; }
if [ "$#" -gt 0 ]; then mods=("$@"); else found=$(discover_mods .) || exit 1; mapfile -t mods <<<"$found"; fi
for m in "${mods[@]}"; do
  [ -f "$m/Cargo.toml" ] || { echo "coverage: $m is not a module (no $m/Cargo.toml)" >&2; exit 1; }
  echo "== coverage $m"
  ( cd "$m" && cargo llvm-cov --locked --fail-under-lines 100 --summary-only ) || { echo "coverage: $m is not at 100% lines (or did not build)" >&2; exit 1; }
done
echo "coverage: OK (${#mods[@]} modules, 100% lines each)"
