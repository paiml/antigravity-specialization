# m4: falsifiers: can the gate refuse an empty artifact

Each demo is a bin under `src/bin/` with a `Provable contract:` docstring line,
a closing `assert!` and `println!("contract: ... OK")`. Run them from `m4/`.

| Bin / step | Shows | Run |
|---|---|---|
| `m4_empty_gate` | the gate that cannot say no | `cargo run -q --bin m4_empty_gate` |
| `m4_falsifier` | write the falsifier first | `cargo run -q --bin m4_falsifier` |
| contracts as a graph | `contracts/*.yaml`, `contracts/contracts.nt`, `contracts/shapes.ttl` | `pv extract contracts && pv census` |
| determinism: extract --check | the pv step of `scripts/gate.sh` | `pv extract contracts --check` |
| `m4_waiver_levers` | a gate has two states (`fixtures/pv-lint-levers.txt`) | `cargo run -q --bin m4_waiver_levers` |
| `m4_referee` | do not let the agent edit the referee (`../fixtures/agy-runs/m4-referee/`) | `cargo run -q --bin m4_referee` |

Fixtures are recorded output, never edited (the recorded agy stdout has its scratch
paths shortened to `arena/`):

- `fixtures/report-red.txt`: the arena's `sh gate.sh` before the agent ran (one failing test).
- `fixtures/report-green.txt`: the arena's test binary after the recorded agy patch (5 tests).
- `fixtures/report-empty.txt`: the empty artifact. Zero bytes on purpose.
- `fixtures/planted-loosened.diff`, `fixtures/planted-gate.txt`: a planted patch that lowers
  `gate.floor` to 3 and adds `|| true` to the test run, and the arena gate printing `gate: OK` on it.
  The agent did not write it; it is planted to show what the referee refuses.
- `fixtures/pv-lint-levers.txt`: four `pv lint` runs (pv 0.75.0) on a copy of `contracts/` whose
  FALSIFY-FLOOR-001 cites a test that does not exist.
