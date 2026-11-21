# Receipts — `courses/c01-the-antigravity-platform`

## Targets

| Target | What it measures | Status |
|---|---|---|
| `test` | Reads `[example].run` (and `[example].requires`) from each `examples/*/example.toml` and runs it inside that example directory; emits `SKIP(live) <dir>` for live `agy`/interactive examples when `LIVE != 1` (listed, never counted as passed); enforces anti-vacuity (`total > 0`) and fails on any missing/invalid `example.toml` or non-zero exit. | **NOT VERIFIED** — shell execution prohibited in this task; `examples/complex-image-processing/example.toml` declares `run = "./remove_star.sh pyramid-star.png out.png"`. |
| `coverage` | Executes `$(MAKE) --no-print-directory test` and verifies every `examples/*/` directory appears in the test output strictly as `PASS <dir>` or `SKIP(live) <dir>` (never `FAIL` or missing, with `skip_live` tracked separately from `pass`), failing if zero examples are found (anti-vacuity) or if `test` fails. | **NOT VERIFIED** — shell execution prohibited in this task. |
| `pv` | Intended to match the `c04` `pv` gate. Kept unchanged (fails loudly without guessing a command because no `c04` / `scripts/record-ready.sh` precedent exists in this worktree). | **NOT FOUND / NOT VERIFIED** — `scripts/record-ready.sh`, `courses/c04-falsify-the-agent/Makefile`, and `contracts/` do not exist in this worktree. |
| `gate` | Composite target `gate: test coverage pv`. | **NOT VERIFIED** — shell execution prohibited and `pv` remains blocked without `c04` / `scripts/record-ready.sh` precedent in this worktree. |

## Precedent Search Results

- `scripts/record-ready.sh`: **NOT FOUND** in this worktree (therefore `test` parses and runs each `examples/*/example.toml` `[example].run` directly rather than delegating to `scripts/record-ready.sh`).
- `courses/c04-falsify-the-agent/Makefile`: **NOT FOUND** (`specialization.toml` declares only `courses/c01-the-antigravity-platform` and `courses/c02-antigravity-internals`).
- `scripts/gate.sh`, `scripts/coverage.sh`, `contracts/`: **NOT FOUND** in this worktree.
- `courses/c01-the-antigravity-platform/examples/complex-image-processing/example.toml`: **FOUND** (`run = "./remove_star.sh pyramid-star.png out.png"`, `requires = "Requires ImageMagick 6 (\`convert\`). On ImageMagick 7, use \`magick\`."`; no `verify.sh` exists in this directory).
- `.github/workflows/gate.yml` and `.github/scripts/check-readme-consistency.sh`: **FOUND** (repository README consistency gate).

## Verification

- **NOT VERIFIED**: `make test`, `make coverage`, `make pv`, `make gate`, `./remove_star.sh pyramid-star.png out.png`, and `.github/scripts/check-readme-consistency.sh` were not executed because shell command execution was disallowed in this task; nothing live was verified.
