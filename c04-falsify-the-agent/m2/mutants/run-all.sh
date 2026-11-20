#!/usr/bin/env bash
# Re-measures every saved mutation run under m2/mutants/ (not part of the pull-request gate).
# Run on a machine with cargo-mutants. It installs nothing. Each run writes its lists,
# the exact command and its output.
# `-- --lib` scores the unit tests only. The integration test runs the demo bins,
# which read these saved lists and replay source files byte for byte, so it would
# "catch" every source mutant for the wrong reason.
set -euo pipefail
cd "$(dirname "$0")/.."
cargo mutants --version >/dev/null || { echo "run-all: cargo-mutants missing" >&2; exit 1; }
out="$(mktemp -d)"
trap 'rm -rf -- "${out:?}"' EXIT
run() {
  local name="$1"; shift
  local dest="mutants/$name"
  mkdir -p "$dest"
  echo "cargo mutants --no-shuffle --timeout 300 -o <tmpdir> $*" > "$dest/command.txt"
  mkdir -p "$out/$name"
  set +e
  cargo mutants --no-shuffle --timeout 300 -o "$out/$name" "$@" > "$dest/run.txt" 2>&1
  echo "exit=$?" >> "$dest/run.txt"
  set -e
  for list in caught missed timeout unviable; do
    cp "$out/$name/mutants.out/$list.txt" "$dest/$list.txt"
  done
}
run price-weak --file src/price.rs -- --lib
run price-kill --file src/price.rs --features kill -- --lib
run cap --file src/cap.rs -- --lib
run agent-suite --file src/agent_shipping.rs -- --lib
run diff-scope/full --file src/price.rs --file src/bulk.rs -- --lib
run diff-scope/in-diff --in-diff mutants/diff-scope/change.diff -- --lib
echo "run-all: OK"
