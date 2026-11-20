#!/usr/bin/env bash
# Print the coverage, mutant and test-list numbers the m1 demos show.
# Run on a build host that has cargo-llvm-cov and cargo-mutants (any build host).
# It installs nothing and writes only under a temporary directory; it prints to stdout.
set -u
cd "$(dirname "$0")/../.."
runs=fixtures/agy-runs
work="$(mktemp -d)"
for tool in llvm-cov mutants; do
  cargo "$tool" --version >/dev/null 2>&1 || { echo "measure: cargo-$tool missing" >&2; exit 1; }
done
echo "host $(hostname) $(date -u +%FT%TZ) $(cargo --version) $(cargo llvm-cov --version) $(cargo mutants --version)"
for s in m1-cold-open m1-deleted-test; do
  cp -r "$runs/$s/crate" "$work/$s-before"
  cp -r "$runs/$s/crate" "$work/$s-after"
  patch -s -d "$work/$s-after" -p1 < "$runs/$s/patch.diff"
done
cp -r m1/fixtures/vacuous-suite "$work/vacuous-suite-after"
for v in m1-cold-open-before m1-cold-open-after vacuous-suite-after; do
  ( cd "$work/$v"
    echo "== $v cargo llvm-cov --summary-only"; cargo llvm-cov --summary-only 2>&1 | tail -n 12; echo "exit=${PIPESTATUS[0]}"
    echo "== $v cargo mutants"; cargo mutants --no-shuffle 2>&1 | tail -n 40; echo "exit=${PIPESTATUS[0]}"
    echo "== $v mutants.out/caught.txt"; cat mutants.out/caught.txt )
done
for v in m1-deleted-test-before m1-deleted-test-after; do
  ( cd "$work/$v"
    echo "== $v cargo test"; cargo test 2>&1 | tail -n 15; echo "exit=${PIPESTATUS[0]}"
    echo "== $v cargo test -- --list"; cargo test -q -- --list 2>/dev/null; echo "exit=${PIPESTATUS[0]}"
    echo "== $v cargo test -- --list --ignored"; cargo test -q -- --list --ignored 2>/dev/null; echo "exit=${PIPESTATUS[0]}" )
done
