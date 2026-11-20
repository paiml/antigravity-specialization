#!/usr/bin/env bash
# The gate for course 4. CI runs this, then scripts/coverage.sh; `make gate` runs both.
#   scripts/gate.sh            every module present (m1..m6)
#   scripts/gate.sh m1 m3      just those modules
# Each module mN/ is its own cargo workspace with its own Cargo.lock.
# It checks for its tools and goes red when one is missing. It installs nothing.
#   scripts/gate.sh --self-test  feed its checks known-bad input, then plant each defect in a
#                                copy of the course (scripts/self-test.sh): every one must be refused
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck source=lib.sh
. scripts/lib.sh
if [ "${1-}" = --self-test ]; then self_test_lib && exec bash scripts/self-test.sh gate; exit 1; fi

for tool in cargo rustfmt pv; do
  command -v "$tool" >/dev/null || { echo "gate: missing tool: $tool" >&2; exit 1; }
done

if [ "$#" -gt 0 ]; then mods=("$@"); else found=$(discover_mods .) || exit 1; mapfile -t mods <<<"$found"; fi
[ "${#mods[@]}" -gt 0 ] || { echo "gate: no module found; an empty course is refused" >&2; exit 1; }

log="$(mktemp)"
trap 'rm -f -- "${log:?}"' EXIT
total_bins=0
total_dirs=0
for m in "${mods[@]}"; do
  [ -f "$m/Cargo.toml" ] || { echo "gate: $m is not a module (no $m/Cargo.toml)" >&2; exit 1; }
  grep -q '^\[workspace\]' "$m/Cargo.toml" || { echo "gate: $m/Cargo.toml is not its own workspace" >&2; exit 1; }
  [ -f "$m/Cargo.lock" ] || { echo "gate: $m has no Cargo.lock" >&2; exit 1; }
  echo "== gate $m"
  (
    cd "$m"
    cargo fmt --all -- --check
    cargo clippy --all-targets --locked -- -D warnings
    cargo test --locked 2>&1 | tee "$log"
  )
  ran=$(sum_passed "$log")
  require_positive "$ran" "$m ran no test; a module with no test is refused" || exit 1

  # Every demo bin must end with its contract line. A module with no bin is refused.
  bins=0
  for src in "$m"/src/bin/*.rs; do
    [ -e "$src" ] || continue
    bin="$(basename "$src" .rs)"
    grep -q 'Provable contract:' "$src" || { echo "gate: $src has no 'Provable contract:' line" >&2; exit 1; }
    last="$(cd "$m" && cargo run -q --locked --bin "$bin" | tail -n 1)"
    case "$last" in
      "contract: "*" OK") ;;
      *) echo "gate: $bin did not end with 'contract: ... OK' (got: $last)" >&2; exit 1 ;;
    esac
    bins=$((bins + 1))
  done
  [ "$bins" -gt 0 ] || { echo "gate: $m has no demo bin; an empty module is refused" >&2; exit 1; }

  # pv ontology gate when the module carries contracts. pv reads every
  # contracts/*.yaml except binding.yaml as a contract, and so does this gate.
  dirs=0
  cited=0
  if [ -d "$m/contracts" ]; then
    contracts=()
    for f in "$m"/contracts/*.yaml; do
      [ -e "$f" ] && [ "$(basename "$f")" != binding.yaml ] && contracts+=("$f")
    done
    [ "${#contracts[@]}" -gt 0 ] || { echo "gate: $m/contracts holds no contract" >&2; exit 1; }
    (
      cd "$m"
      [ -f contracts/binding.yaml ] || { echo "gate: $m/contracts has no binding.yaml" >&2; exit 1; }
      pv lint contracts --binding contracts/binding.yaml
      # The default lint leaves the bindings gate unarmed, so arm it by name.
      pv lint contracts --binding contracts/binding.yaml --gate bindings
      # pv reports a dangling falsification test as PV-VER-002 but still passes
      # the lint, so any PV-VER error is refused here.
      pv lint contracts --binding contracts/binding.yaml --strict-test-binding --strict >"$log" 2>&1 || true
      if grep -E '\[ERROR\] PV-VER' "$log" >&2; then echo "gate: $m cites a test that does not exist" >&2; exit 1; fi
      pv obligations --gate .
      pv extract contracts --check
    )
    # Every contract cites at least one falsification test, each a different test
    # named last on a `cargo test` line, and each one is run: it must pass and run
    # exactly that one test. This proves the named test exists, runs and passes;
    # whether it exercises the rule it is cited for is for review to judge.
    for f in "${contracts[@]}"; do
      seen=0
      cmds=$(cited_commands "$f") || exit 1
      while IFS= read -r cmd; do
        read -ra argv <<<"$cmd"
        (cd "$m" && cargo test --locked "${argv[@]:2}" 2>&1) >"$log" || { cat "$log" >&2; echo "gate: $f: $cmd failed" >&2; exit 1; }
        require_one_named "$log" "${argv[${#argv[@]}-1]}" || { echo "gate: $f: $cmd" >&2; exit 1; }
        seen=$((seen + 1))
      done <<<"$cmds"
      cited=$((cited + seen))
    done
    dirs=1
  fi
  echo "gate: $m OK ($ran tests, $bins demo bins, $dirs contract dir, $cited falsification tests)"
  total_bins=$((total_bins + bins))
  total_dirs=$((total_dirs + dirs))
done
[ "$total_dirs" -gt 0 ] || { echo "gate: no module carries contracts; an empty corpus is refused" >&2; exit 1; }

echo "gate: OK (${#mods[@]} modules, $total_bins demo bins, $total_dirs contract dirs)"
