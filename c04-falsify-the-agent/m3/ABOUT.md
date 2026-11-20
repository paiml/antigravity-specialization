# m3: contracts and properties on agent output

One function, `clamp`, and the checks that judge what an agent writes about it.
Each demo is a bin under `src/bin/` with a `Provable contract:` docstring line,
a closing `assert!` and `println!("contract: ... OK")`. pv contracts for this module live in
`m3/contracts/` (with `binding.yaml`); `scripts/gate.sh` checks every `m*/contracts` it finds.

| Bin | Shows | Reads |
|---|---|---|
| `m3_named_test_gate` | the test a contract names must exist | `fixtures/agent/m3-named-test/` (agy run), `fixtures/hand/dangling/` (hand-written) |
| `m3_props` | from examples to properties | `src/props.rs` |
| `m3_shrink` | shrinking, reading the counterexample | `src/props.rs`, `proptest-regressions/clamp-escape.txt` |
| `m3_replay` | the agent's patch, replayed against the property tests | `fixtures/agy-runs/m3-clamp-width/patch.diff` (agy run) |
| `m3_vacuous_contract` | the agent wrote the contract too | `fixtures/agent/m3-clamp-width/contracts/` (agy run), `fixtures/hand/symbolic/` (hand-written) |

Kani: `src/proofs.rs` holds one harness for `clamp-v1`, compiled only under `cargo kani`
(the crate keeps `rust-version = "1.93"` so the rustc that cargo-kani ships builds it).

Measured, as it happened:

- In the named-test run the agent did not invent a test name: it cited the one real test and
  refused to bind the item no test checks. The dangling-name case is hand-written. In text mode
  `pv lint --strict-test-binding --strict` prints `PV-VER-002`, then `Result: PASS` and exit 0;
  the JSON `"passed": false` is what the gate reads.
- The proptest shrink is not minimal: `(0, 70697745951424350, 0)`, the same at 1024, 4096 and
  100000 shrink iterations.
- The agent's saturating `clamp_to_width` is correct (it agrees with an `i128` oracle on 256 cases);
  the red case is a hand-written wrapping version.
- The contract the agent wrote is valid and lints PASS, but `pv check-symbolic` finds 0 invariants
  that hold and 2 unparsed, and exits 0. `m3_vacuous_contract` refuses it.
