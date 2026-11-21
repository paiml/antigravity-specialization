# Receipts — `courses/c01-the-antigravity-platform`

## Targets

| Target | What it measures | Status |
|---|---|---|
| `test` | Reads `[example].run` (and `[example].requires`) from each `examples/*/example.toml` and runs it inside that example directory; emits `SKIP(live) <dir>` for live `agy`/interactive examples when `LIVE != 1` (listed, never counted as passed); enforces anti-vacuity (`total > 0`) and fails on any missing/invalid `example.toml` or non-zero exit. | RAN: EXIT=0.|
| `coverage` | Executes `$(MAKE) --no-print-directory test` and verifies every `examples/*/` directory appears in the test output strictly as `PASS <dir>` or `SKIP(live) <dir>` (never `FAIL` or missing, with `skip_live` tracked separately from `pass`), failing if zero examples are found (anti-vacuity) or if `test` fails. | RAN: EXIT=0.|
| `pv` | Runs `pv lint contracts --gate $$g --format json` across `PV_GATES := sigma shapes` against `contracts/` (`contracts/c01-demos-v1.yaml`), requiring `"verdict": "Pass"` for each gate. | RAN: EXIT=0.|
| `gate` | Composite target `gate: test coverage pv`. | RAN: EXIT=0. |

## Precedent Search Results

- `/mnt/nvme-raid0/tmp/rmedia-cop/agy-w/rr-responsible-local-llms/Makefile` and `contracts/`: **READ** (precedent for `PV_GATES := sigma shapes`, `pv lint contracts --gate $$g --format json`, and the contract YAML schema).
- `courses/c01-the-antigravity-platform/contracts/c01-demos-v1.yaml`: **ADDED** (provable contract encoding the chapter invariants asserted by `Makefile`, `example.toml`, and `RECEIPTS.md`).
- `scripts/record-ready.sh`: **NOT FOUND** in this worktree (therefore `test` parses and runs each `examples/*/example.toml` `[example].run` directly rather than delegating to `scripts/record-ready.sh`).
- `courses/c04-falsify-the-agent/Makefile`: **NOT FOUND** (`specialization.toml` declares only `courses/c01-the-antigravity-platform` and `courses/c02-antigravity-internals`).
- `scripts/gate.sh`, `scripts/coverage.sh`: **NOT FOUND** in this worktree.
- `courses/c01-the-antigravity-platform/examples/complex-image-processing/example.toml`: **FOUND** (`run = "./remove_star.sh pyramid-star.png out.png"`, `requires = "Requires ImageMagick 6 (\`convert\`). On ImageMagick 7, use \`magick\`."`; no `verify.sh` exists in this directory).
- `.github/workflows/gate.yml` and `.github/scripts/check-readme-consistency.sh`: **FOUND** (repository README consistency gate).

## Verification

- **RAN on kfocus 2026-11-21 (main c29d8a2 + this branch): `make gate` EXIT=0: test PASS (complex-image-processing, ImageMagick 7.1.2), coverage 1/1, pv sigma Pass, shapes Pass.**
