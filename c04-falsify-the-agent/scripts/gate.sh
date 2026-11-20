#!/usr/bin/env bash
# The gate for course 4. CI runs this, then scripts/coverage.sh; `make gate` runs both.
#   scripts/gate.sh            every module present (m1..m6)
#   scripts/gate.sh m1 m3      just those modules
# Each module mN/ is its own cargo workspace with its own Cargo.lock.
# It checks for its tools and goes red when one is missing. It installs nothing.
set -euo pipefail
cd "$(dirname "$0")/.."

for tool in cargo rustfmt pv; do
  command -v "$tool" >/dev/null || { echo "gate: missing tool: $tool" >&2; exit 1; }
done

if [ "$#" -gt 0 ]; then mods=("$@"); else mods=(); for d in m*/Cargo.toml; do [ -e "$d" ] && mods+=("${d%/Cargo.toml}"); done; fi
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
  ran=$(sed -nE "s/^test result: ok\. ([0-9]+) passed.*/\1/p" "$log" | awk "{s+=\$1} END {print s+0}")
  [ "$ran" -gt 0 ] || { echo "gate: $m ran no test; a module with no test is refused" >&2; exit 1; }

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
    # Every contract cites at least one falsification test, and each one is run:
    # it must pass and must select a subset of the suite (a bare `cargo test`
    # that runs everything proves nothing about the named rule).
    for f in "${contracts[@]}"; do
      seen=0
      while IFS= read -r line; do
        v=${line#*test:}; v=${v#"${v%%[![:space:]]*}"}
        if [[ $v =~ ^\"([^\"]*)\"[[:space:]]*(#.*)?$ ]] || [[ $v =~ ^\'([^\']*)\'[[:space:]]*(#.*)?$ ]]; then cmd=${BASH_REMATCH[1]}
        elif [[ $v =~ ^([^\"\'#][^#]*)(#.*)?$ ]]; then cmd=${BASH_REMATCH[1]}; cmd=${cmd%"${cmd##*[![:space:]]}"}
        else echo "gate: $f: cannot read test line: $line" >&2; exit 1; fi
        read -ra argv <<<"$cmd"
        [ "${argv[0]-}" = cargo ] && [ "${argv[1]-}" = test ] || { echo "gate: $f cites a falsification test that is not a cargo test: $cmd" >&2; exit 1; }
        (cd "$m" && cargo test --locked "${argv[@]:2}" 2>&1) >"$log" || { cat "$log" >&2; echo "gate: $f: $cmd failed" >&2; exit 1; }
        n=$(sed -nE 's/^test result: ok\. ([0-9]+) passed.*/\1/p' "$log" | awk '{s+=$1} END {print s+0}')
        out=$(sed -nE 's/^test result: ok\..* ([0-9]+) filtered out.*/\1/p' "$log" | awk '{s+=$1} END {print s+0}')
        [ "$n" -gt 0 ] || { echo "gate: $f: $cmd ran no test (the cited test does not exist)" >&2; exit 1; }
        [ "$out" -gt 0 ] || { echo "gate: $f: $cmd selects no subset of the suite; name the test" >&2; exit 1; }
        seen=$((seen + 1))
      done < <(grep -E '^[[:space:]]*(-[[:space:]]+)?test:' "$f")
      [ "$seen" -gt 0 ] || { echo "gate: $f cites no falsification test" >&2; exit 1; }
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
