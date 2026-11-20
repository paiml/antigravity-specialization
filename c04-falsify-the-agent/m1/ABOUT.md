# Module 1: The vacuous green

Owner: the module 1 worker. Touch only `m1/`.

Each lesson demo is a bin under `src/bin/` with a `Provable contract:` docstring line,
a closing `assert!` and `println!("contract: ... OK")`. pv contracts for this module live in
`m1/contracts/` (with `binding.yaml`); `scripts/gate.sh` checks every `m*/contracts` it finds.

| Lesson | Bin | Reads |
|---|---|---|
| 1.1 Cold open | `m1_cold_open` | `fixtures/agy-runs/m1-cold-open/measured/` (agy run, measured on a build host) |
| 1.2 The test that cannot fail | `m1_vacuous` | `src/vacuous.rs` |
| 1.3 100% is a claim, not a fact | `m1_covered_not_checked` | the agy patch, and `fixtures/vacuous-suite/` (hand-written) |
| 1.4 The deleted test | `m1_test_floor` | `fixtures/agy-runs/m1-deleted-test/measured/` (agy run; red rows hand-written) |

Measured truth, not the outline's premise: the agy suite in the cold open reaches 52/52
lines and catches 28 of 29 mutants (the survivor, `> with >=` at `src/lib.rs:9:21`, is
equivalent at weight 1000). In the deleted-test run the agy agent fixed the code and kept
all 5 tests. Both are recorded as they happened.

Re-measure: `bash m1/scripts/measure-on-build-host.sh` on a host with cargo-llvm-cov and
cargo-mutants. Contract: `contracts/test-floor-v1.yaml`, bound to `m1::floor::check`.
