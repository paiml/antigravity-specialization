#!/usr/bin/env bash
# End-to-end self-test for scripts/gate.sh and scripts/coverage.sh. It copies the
# scripts, the toolchain pin and module m1 with its recorded runs (the fixture every
# case edits; other modules stay out, so the cases hold whatever else the course
# carries) into a scratch directory, plants one defect per case, runs the real
# script on the copy and requires it to go red with the reason that defect must
# produce.
# A clean copy must go green first, so no red below comes from a broken baseline.
# The first case that does not hold stops the run, red.
#   scripts/self-test.sh gate        (run by scripts/gate.sh --self-test)
#   scripts/self-test.sh coverage    (run by scripts/coverage.sh --self-test)
set -euo pipefail
which=${1-}
case "$which" in gate | coverage) ;; *) echo "self-test: usage: self-test.sh gate|coverage" >&2; exit 2 ;; esac
src="$(cd "$(dirname "$0")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf -- "${work:?}"' EXIT
# Each copy builds into its own target dir. Cases that leave the Rust sources alone
# share copy c, restored with its file mtimes, so nothing rebuilds; a case that edits
# Rust gets its own copy and target, so its build never leaks into another case
# (cargo judges freshness by mtime, and two copies of m1 hash alike).
pass=0
c=m1/contracts/test-floor-v1.yaml

fresh() { # fresh DIR: a clean copy of scripts, m1 and what m1 reads at $work/DIR (file mtimes kept)
  rm -rf -- "${work:?}/${1:?}"
  mkdir -p "$work/$1"
  (cd "$src" && tar --exclude=./m*/target --exclude=.pv --exclude='mutants.out*' --exclude='*.profraw' -cf - ./scripts ./rust-toolchain.toml ./m1 ./fixtures/agy-runs/m1-*) | tar -C "$work/$1" -xf -
}
run() { # run DIR NAME [ARGS]: the script under test on copy DIR; output in NAME.log
  local dir=$1 name=$2; shift 2
  set +e
  CARGO_TARGET_DIR="$work/target-$dir" bash "$work/$dir/scripts/$which.sh" "$@" >"$work/$name.log" 2>&1
  rc=$?
  set -e
}
fail() { # fail NAME WHY: stop the self-test red
  echo "self-test $which: FAIL $1: $2" >&2
  tail -n 25 "$work/$1.log" >&2 || true
  exit 1
}
green() { # green DIR NAME [ARGS]
  run "$@"
  [ "$rc" -eq 0 ] || fail "$2" "went red; it must be accepted"
  pass=$((pass + 1))
  echo "self-test $which: ok $2 (green)"
}
red() { # red DIR NAME REASON [ARGS]: must exit non-zero and print REASON
  local dir=$1 name=$2 reason=$3; shift 3
  run "$dir" "$name" "$@"
  [ "$rc" -ne 0 ] || fail "$name" "went green; it must be refused with: $reason"
  grep -qF -- "$reason" "$work/$name.log" || fail "$name" "went red, but not with: $reason"
  pass=$((pass + 1))
  echo "self-test $which: ok $name (red: $reason)"
}
regen() { (cd "$work/$1/m1" && pv extract contracts >/dev/null); } # after a planted contract edit
cite() { # cite DIR NEW: the FALSIFY-FLOOR-002 command becomes NEW
  sed -i "s|cargo test --lib an_ignored_test_is_red|$2|" "$work/$1/$c"
  regen "$1"
}
replace_floor_002() { # replace_floor_002 DIR TEXT: TEXT takes the place of the FALSIFY-FLOOR-002 entry
  sed -i '/^  - id: FALSIFY-FLOOR-002$/,$d' "$work/$1/$c"
  printf '%s\n' "$2" >>"$work/$1/$c"
  regen "$1"
}
no_manifest() { # a module directory whose Cargo.toml is misnamed
  mkdir -p "$work/$1/m2"
  cp -a "$work/$1/m1/src" "$work/$1/m1/contracts" "$work/$1/m2/"
  cp "$work/$1/m1/Cargo.toml" "$work/$1/m2/cargo.toml"
}

if [ "$which" = gate ]; then
  fresh c; green c clean

  # Refusals before any build.
  fresh c; bin="$work/bin"; mkdir -p "$bin"
  ln -sf "$(command -v cargo)" "$bin/cargo"; ln -sf "$(command -v rustfmt)" "$bin/rustfmt"
  if PATH="$bin:/usr/bin:/bin" command -v pv >/dev/null; then echo "self-test gate: FAIL cannot plant a missing pv: one is on /usr/bin:/bin" >&2; exit 1; fi
  PATH="$bin:/usr/bin:/bin" run c missing-tool
  [ "$rc" -ne 0 ] && grep -qF "gate: missing tool: pv" "$work/missing-tool.log" || fail missing-tool "a missing pv must be refused by name"
  pass=$((pass + 1)); echo "self-test gate: ok missing-tool (red)"
  fresh c; rm -rf -- "${work:?}/c/m1"; red c no-module "no module found"
  fresh c; no_manifest c; red c no-manifest "m2 has no Cargo.toml"
  fresh c; mkdir -p "$work/c/m9"; red c named-non-module "gate: m9 is not a module" m9
  fresh c; sed -i '/^\[workspace\]$/d' "$work/c/m1/Cargo.toml"; red c not-a-workspace "is not its own workspace"
  fresh c; rm -f -- "${work:?}/c/m1/Cargo.lock"; red c no-lock "m1 has no Cargo.lock"

  # Rust defects: each in its own copy.
  fresh fmt; printf '\npub fn  planted_unformatted( ) -> u32 { 1 }\n' >>"$work/fmt/m1/src/lib.rs"
  red fmt fmt "planted_unformatted"
  fresh clippy; printf '\npub fn planted_lint(v: &[u8]) -> bool {\n    v.len() == 0\n}\n' >>"$work/clippy/m1/src/lib.rs"
  red clippy clippy "len_zero"
  fresh failing; printf '\n#[test]\nfn planted_red() {\n    panic!("planted failing test");\n}\n' >>"$work/failing/m1/src/lib.rs"
  red failing failing "planted failing test"
  fresh ignored
  find "$work/ignored/m1/src" "$work/ignored/m1/tests" -name '*.rs' -exec sed -i 's/^\([[:space:]]*\)#\[test\]$/\1#[test]\n\1#[ignore]/' {} +
  red ignored ignored "m1 ran no test"
  fresh nocontract; sed -i 's/Provable contract:/Contract:/' "$work/nocontract/m1/src/bin/m1_vacuous.rs"
  red nocontract bin-without-contract-line "has no 'Provable contract:' line"
  fresh lastline; printf '//! Provable contract: planted.\nfn main() {\n    println!("done");\n}\n' >"$work/lastline/m1/src/bin/m1_planted.rs"
  red lastline bin-without-ok-line "m1_planted did not end with 'contract: ... OK'"
  fresh nobin; rm -rf -- "${work:?}/nobin/m1/src/bin" "${work:?}/nobin/m1/tests"
  red nobin no-bin "m1 has no demo bin"

  # Contract defects: the Rust sources are untouched, so they share copy c.
  fresh c; rm -rf -- "${work:?}/c/m1/contracts"; red c no-contract-dir "no module carries contracts"
  fresh c; rm -f -- "${work:?}/c/$c"; red c no-contract "m1/contracts holds no contract"
  fresh c; rm -f -- "${work:?}/c/m1/contracts/binding.yaml"; red c no-binding "m1/contracts has no binding.yaml"
  fresh c; sed -i 's/^  kind: pattern$/  kind: nonsense/' "$work/c/$c"; red c lint "PV-VAL-001"
  fresh c; sed -i 's/^    function: "check"$/    function: "no_such_fn"/' "$work/c/m1/contracts/binding.yaml"
  red c broken-binding "0/1 armed gates passed"
  fresh c; cite c "cargo test --lib planted_missing_test"; red c dangling-test "m1 cites a test that does not exist"
  fresh c; sed -i 's/^    applies_to: check$/    applies_to: no_such_fn/' "$work/c/$c"; regen c
  red c obligations "obligation gate failed"
  fresh c; echo '<urn:planted> <urn:planted> <urn:planted> .' >>"$work/c/m1/contracts/contracts.nt"
  red c stale-extract "differs from a fresh extraction"
  fresh c; sed -i '/^falsification_tests:$/,$d' "$work/c/$c"; regen c
  red c cites-none "cites no falsification test"
  fresh c; cite c "echo an_ignored_test_is_red"; red c not-cargo-test "is not a cargo test"
  fresh c; cite c "cargo test --lib -- --skip a_deleted_test_is_red"; red c skip "skips or passes through test flags"
  fresh c; cite c "cargo test --lib"; red c names-no-test "must end with the name of the test it runs"
  fresh c; cite c "cargo test --lib a_deleted_test_is_red"; red c cited-twice "cites a_deleted_test_is_red twice"
  fresh c; cite c "cargo test --lib is_red"; red c broad-filter "must run exactly the one test it names"
  fresh c; cite c "cargo test --lib vacuous_passes_the_wrong_body"; red c other-target "ran 0 tests"
  fresh c; cite c "cargo test --test no_such_target an_ignored_test_is_red"; red c cited-fails "no_such_target an_ignored_test_is_red failed"
  fresh c
  replace_floor_002 c '  - {id: FALSIFY-FLOOR-002, rule: NO_IGNORE, prediction: "x", test: "cargo test --lib", if_fails: "y"}'
  red c flow-style "flow style is refused"
else
  fresh c; green c clean
  fresh c; rm -rf -- "${work:?}/c/m1"; red c no-module "no module found"
  fresh c; no_manifest c; red c no-manifest "m2 has no Cargo.toml"
  fresh c; mkdir -p "$work/c/m9"; red c named-non-module "coverage: m9 is not a module" m9
  fresh under
  printf '\npub fn planted_uncovered(x: u32) -> u32 {\n    if x > 1 {\n        x * 2\n    } else {\n        x + 1\n    }\n}\n' >>"$work/under/m1/src/lib.rs"
  red under under-100 "coverage: m1 is not at 100% lines"
fi

echo "self-test $which: OK ($pass cases)"
