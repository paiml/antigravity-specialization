# Module 6: Second-model review and the capstone

| Bin | What it shows |
|---|---|
| `m6_judge` | The author's own summary is not a review; two second reviews caught the empty tests. |
| `m6_tally` | Three recorded seats, one decision; a silent seat is not a yes. |
| `m6_mutant_list` | 6/6 mutants caught, two tests empty; only the review handed the list said so. |
| `m6_receipt` | The capstone receipts, rebuilt from measured gates; cut or edited receipts are refused. |

Run one: `cargo run -q --bin m6_judge`.

Records (never edited; nothing here calls a model):

- `fixtures/agy-runs/m6-*`: real agy runs (capstone, three reviews).
- `fixtures/reviews/m6-*`: real Claude Code reviews, kept apart from the agy runs.
- `fixtures/subject/`: the review subject (the capstone patch with the assertions of two tests
  removed by hand, on purpose) and real `cargo mutants` output on it.
- `fixtures/receipts/`: the two capstone receipts; `m6_receipt` rebuilds them byte for byte.

`src/shop.rs` is the capstone agent patch, replayed; `tests/capstone_replay.rs` proves it.
The pv contract is `contracts/discount-v1.yaml`.
