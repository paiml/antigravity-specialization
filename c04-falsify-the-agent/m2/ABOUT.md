# m2: mutation testing, who tests the tests

Each demo is a bin under `src/bin/` with a `Provable contract:` docstring line,
a closing `assert!` and `println!("contract: ... OK")`.

| Bin | Shows | Code under test | Saved run |
|---|---|---|---|
| `m2_mutant` | what a mutant is | `src/price.rs`, weak suite | `mutants/price-weak/` |
| `m2_kill` | kill the survivor | `src/price.rs`, `--features kill` | `mutants/price-kill/` |
| `m2_equivalent` | equivalent mutants and the honest score | `src/cap.rs` | `mutants/cap/` + `equivalents.txt` |
| `m2_agent_suite` | mutation on agent output | `src/agent_shipping.rs` (the agy patch, verbatim) | `mutants/agent-suite/` |
| `m2_diff_scope` | mutation scoped to a diff | `src/bulk.rs` via `mutants/diff-scope/change.diff` | `mutants/diff-scope/{full,in-diff}/` |

- Every number a bin prints comes from a saved `cargo mutants` run. Each run directory holds
  `command.txt` (the exact command), `run.txt` (its output and exit code) and the four lists.
- `mutants/run-all.sh` re-measures them on a machine with cargo-mutants. It is not part of the
  pull-request gate, and it installs nothing.
- Mutation runs pass `-- --lib`: they score the unit tests. `tests/` replays source files
  byte for byte, so it would catch every source mutant for the wrong reason.
- pv: `contracts/kill-rate-v1.yaml` binds `score::kill_rate` (an empty run has no score).
- The agy run that `m2_agent_suite` replays is recorded in `../fixtures/agy-runs/m2-agent-suite/`.
