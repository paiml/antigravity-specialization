#!/usr/bin/env bash
# Shared checks for gate.sh and coverage.sh. Sourced, never run. Each function
# prints its refusal on stderr and returns 1; --self-test in both scripts feeds
# them known-bad input and demands the refusal.

# discover_mods ROOT: print each module directory (m*) under ROOT, one per line.
# A m* directory with no Cargo.toml is refused, not skipped: a misnamed manifest
# must not let a module through unchecked. An empty course is refused too.
discover_mods() {
  local root=$1 d n=0
  for d in "$root"/m*/; do
    [ -d "$d" ] || continue
    d=${d%/}
    [ -f "$d/Cargo.toml" ] || { echo "gate: ${d##*/} has no Cargo.toml; a module directory without a manifest is refused" >&2; return 1; }
    echo "${d##*/}"
    n=$((n + 1))
  done
  [ "$n" -gt 0 ] || { echo "gate: no module found; an empty course is refused" >&2; return 1; }
}

# sum_matches LOG: sum the first number of every cargo "test result: ok" line
# for the given sed capture (passed | filtered).
sum_passed() { sed -nE 's/^test result: ok\. ([0-9]+) passed.*/\1/p' "$1" | awk '{s+=$1} END {print s+0}'; }
sum_filtered() { sed -nE 's/^test result: ok\..* ([0-9]+) filtered out.*/\1/p' "$1" | awk '{s+=$1} END {print s+0}'; }

# require_positive N WHAT: refuse zero (and anything that is not a number).
require_positive() {
  [[ $1 =~ ^[0-9]+$ ]] && [ "$1" -gt 0 ] || { echo "gate: $2" >&2; return 1; }
}

# cited_commands FILE: print the command of every falsification test the
# contract cites, one per line. Refuses a contract that cites none, a line it
# cannot read, a command that is not `cargo test`, a command that skips tests,
# and any `test:` key it did not parse (a flow-style entry puts `test:` mid-line,
# so the count of keys must equal the count of parsed lines).
cited_commands() {
  local f=$1 line v cmd seen=0 keys
  local -a argv
  while IFS= read -r line; do
    v=${line#*test:}; v=${v#"${v%%[![:space:]]*}"}
    if [[ $v =~ ^\"([^\"]*)\"[[:space:]]*(#.*)?$ ]] || [[ $v =~ ^\'([^\']*)\'[[:space:]]*(#.*)?$ ]]; then cmd=${BASH_REMATCH[1]}
    elif [[ $v =~ ^([^\"\'#][^#]*)(#.*)?$ ]]; then cmd=${BASH_REMATCH[1]}; cmd=${cmd%"${cmd##*[![:space:]]}"}
    else echo "gate: $f: cannot read test line: $line" >&2; return 1; fi
    read -ra argv <<<"$cmd"
    [ "${argv[0]-}" = cargo ] && [ "${argv[1]-}" = test ] || { echo "gate: $f cites a falsification test that is not a cargo test: $cmd" >&2; return 1; }
    case " $cmd " in *" --skip"*) echo "gate: $f: $cmd skips tests; a falsification test must run its named test" >&2; return 1 ;; esac
    echo "$cmd"
    seen=$((seen + 1))
  done < <(grep -E '^[[:space:]]*(-[[:space:]]+)?test:' "$f" || true)
  keys=$(grep -oE '(^|[[:space:],{-])test[[:space:]]*:' "$f" | wc -l)
  [ "$keys" -eq "$seen" ] || { echo "gate: $f has $keys test: keys but only $seen readable block-style lines (flow style is refused)" >&2; return 1; }
  [ "$seen" -gt 0 ] || { echo "gate: $f cites no falsification test" >&2; return 1; }
}

# expect_red DESC CMD...: the self-test helper. CMD must exit non-zero.
expect_red() {
  local desc=$1; shift
  if "$@" >/dev/null 2>&1; then echo "self-test FAILED: '$desc' was accepted" >&2; return 1; fi
  echo "self-test ok: '$desc' is refused"
}
# expect_green DESC CMD...: CMD must exit zero (a gate that refuses everything proves nothing).
expect_green() {
  local desc=$1; shift
  "$@" >/dev/null 2>&1 || { echo "self-test FAILED: '$desc' was refused" >&2; return 1; }
  echo "self-test ok: '$desc' is accepted"
}

# self_test_lib: exercises every function above on fixtures built in a temp dir.
self_test_lib() {
  local t; t=$(mktemp -d)
  # shellcheck disable=SC2064
  trap "rm -rf -- '${t:?}'" RETURN
  mkdir -p "$t/empty" "$t/good/m1" "$t/bad/m1" "$t/bad/m2"
  : >"$t/good/m1/Cargo.toml"; : >"$t/bad/m1/Cargo.toml"
  expect_red "empty course" discover_mods "$t/empty"
  expect_red "module directory with no Cargo.toml" discover_mods "$t/bad"
  expect_green "one module with a manifest" discover_mods "$t/good"

  printf 'test result: ok. 3 passed; 0 failed; 0 ignored; 0 measured; 5 filtered out\n' >"$t/ok.log"
  printf 'test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out\n' >"$t/zero.log"
  : >"$t/none.log"
  [ "$(sum_passed "$t/ok.log")" = 3 ] && [ "$(sum_filtered "$t/ok.log")" = 5 ] || { echo "self-test FAILED: sums" >&2; return 1; }
  expect_green "3 tests passed" require_positive "$(sum_passed "$t/ok.log")" x
  expect_red "zero tests passed" require_positive "$(sum_passed "$t/zero.log")" x
  expect_red "no test result line at all" require_positive "$(sum_passed "$t/none.log")" x
  expect_red "zero tests filtered out" require_positive "$(sum_filtered "$t/zero.log")" x
  expect_red "a non-number count" require_positive "" x

  c() { printf '%s\n' "$@" >"$t/c.yaml"; }
  c '  - id: A' '    test: "cargo test --lib a_named_test"'
  expect_green "block-style quoted test" cited_commands "$t/c.yaml"
  c '  - id: A' "    test: 'cargo test --lib a_named_test'  # note"
  expect_green "single-quoted test with a comment" cited_commands "$t/c.yaml"
  c '  - id: A' '    test: cargo test --lib a_named_test'
  expect_green "unquoted test" cited_commands "$t/c.yaml"
  c '  - id: A'
  expect_red "a contract citing no test" cited_commands "$t/c.yaml"
  c '  - id: A' '    test: "echo a_deleted_test_is_red"'
  expect_red "a command that is not cargo test" cited_commands "$t/c.yaml"
  c '  - id: A' '    test: "cargo test --lib -- --skip a_deleted_test_is_red"'
  expect_red "a command that skips the test" cited_commands "$t/c.yaml"
  c '  - id: A' '    test: "cargo test --lib ok_one"' '  - {id: B, rule: R, test: "cargo test --lib", if_fails: y}'
  expect_red "a flow-style entry beside a block-style one" cited_commands "$t/c.yaml"
  c '  - {id: B, rule: R, test: "echo x", if_fails: y}'
  expect_red "only a flow-style entry" cited_commands "$t/c.yaml"
  c '  - id: A' '    test: "unterminated'
  expect_red "an unreadable test line" cited_commands "$t/c.yaml"
  echo "self-test: lib OK"
}
