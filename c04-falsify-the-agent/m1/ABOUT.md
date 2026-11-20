# m1: a green suite that checks nothing

Each demo is a bin under `src/bin/` with a `Provable contract:` docstring line,
a closing `assert!` and `println!("contract: ... OK")`. pv contracts for this module live in
`m1/contracts/` (with `binding.yaml`); `scripts/gate.sh` checks every `m*/contracts` it finds.

| Bin | Shows | Reads |
|---|---|---|
| `m1_cold_open` | green tests and 100% line coverage, then the mutants | `fixtures/agy-runs/m1-cold-open/measured/` (agy run, measured on a build host) |
| `m1_vacuous` | a test that cannot fail | `src/vacuous.rs` |
| `m1_covered_not_checked` | 100% coverage is a claim, not a fact | the agy patch, and `fixtures/vacuous-suite/` (hand-written) |
| `m1_test_floor` | a test-name floor refuses a deleted test | `fixtures/agy-runs/m1-deleted-test/measured/` (agy run; red rows hand-written) |

Measured, as it happened: the agy suite in the cold open reaches 52/52
lines and catches 28 of 29 mutants (the survivor, `> with >=` at `src/lib.rs:9:21`, is
equivalent at weight 1000). In the deleted-test run the agy agent fixed the code and kept
all 5 tests. Both are recorded as they happened.

Re-measure: `bash m1/scripts/measure-on-build-host.sh` on a host with cargo-llvm-cov and
cargo-mutants. Contract: `contracts/test-floor-v1.yaml`, bound to `m1::floor::check`.
