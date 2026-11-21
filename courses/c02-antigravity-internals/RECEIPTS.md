# Receipts — `courses/c02-antigravity-internals`

## Precedent Lookup

Checked inside this worktree (`/mnt/nvme-raid0/tmp/rmedia-cop/agy-w/rr-ags-c02`):

- `scripts/record-ready.sh` — **NOT FOUND** in this repository worktree (checked `scripts/record-ready.sh`, `record-ready.sh`, `.github/scripts/record-ready.sh`). Therefore `Makefile` could not delegate to `scripts/record-ready.sh` or add a `CHAPTER` filter to it, and instead executes each `examples/*/example.toml` `[example].run` command directly.
- `c04-falsify-the-agent/Makefile` — **NOT FOUND**
- `courses/c04-falsify-the-agent/Makefile` — **NOT FOUND**
- `contracts/` (at repo root, `courses/c04-falsify-the-agent/`, `courses/c02-antigravity-internals/`) — **NOT FOUND**
- `pv` command invocation / `file:line` citation — **NOT FOUND** (no `c04` `pv` precedent exists in this worktree; `pv` remains an explicit `exit 1` refusal rather than a guessed command).

The only repo-level gate present in this worktree is `.github/workflows/gate.yml` calling `.github/scripts/check-readme-consistency.sh`.

## Example Inventory (`examples/*/example.toml`)

| Example | `[example].run` | Classification in `make test` | Notes |
|---|---|---|---|
| `examples/grill-me-first` | `./grill.sh` | `SKIP(live)` | `grill.sh` invokes `agy -i` (interactive Antigravity CLI). Listed, never counted as passed. |
| `examples/explore-and-plan` | `./explore.sh` | `SKIP(live)` | `explore.sh` invokes `agy -p ... --mode plan` (live Antigravity CLI). Listed, never counted as passed. |
| `examples/transpose-image` | `./transpose.sh nostar.png out.png` | Runnable (`PASS` / `FAIL`) | Requires ImageMagick (`magick` or `convert`). |
| `examples/image-pipeline` | `./pipeline.sh pyramid-star.png out.png && ./verify.sh` | Runnable (`PASS` / `FAIL`) | Runs pipeline and `verify.sh` (3 checks). |
| `examples/image-pipeline-skill` | `agy -p 'use the image-pipeline skill on pyramid-star.png'` | `SKIP(live)` | `run` invokes `agy -p` directly. Listed, never counted as passed. |
| `examples/batch-runner` | `cargo run -- --dir images --cmd 'convert {} -transpose +repage {}.t.png'` | Runnable (`PASS` / `FAIL`) | Runs `batch-runner` over `images/`. |
| `examples/pmat-review-agent` | `./verify.sh` | Runnable (`PASS` / `FAIL`) | `verify.sh` invokes `pmat`, not `agy`. |

## Makefile Targets

| Target | What it measures | Status / Notes |
|---|---|---|
| `test` | Iterates `examples/*/`, parses `[example].run` from `example.toml`, marks live `agy` examples as `SKIP(live)` (listed, never counted as passed), executes all other `run` commands via `bash -c` inside each example directory, fails on missing `example.toml`, missing/invalid `run`, any non-zero exit (`FAIL`), or zero `examples/*/` directories (anti-vacuity). | Rewritten to use `example.toml` `[example].run` instead of assuming every `examples/*/` has `verify.sh`. |
| `coverage` | Runs `$(MAKE) --no-print-directory test` capturing its output, enforces an anti-vacuity floor (`dirs > 0`), and asserts every `examples/*/` directory appears exactly once in the test output as `PASS` or `SKIP(live)` (failing on `FAIL`, `MISSING`, `DUPLICATE`, or non-zero `test` exit). | Rewritten to verify `test` output coverage across all `examples/*/` directories. |
| `pv` | Fails loudly (`exit 1`) because `c04` precedent (`c04-falsify-the-agent/Makefile`, `contracts/`) is **NOT FOUND** in this worktree; refuses to guess `pv` commands. | Unchanged (`NOT FOUND`). |
| `gate` | Runs `test coverage pv` in sequence. | Unchanged. |

## NOT VERIFIED

- **Live `agy` examples (`examples/grill-me-first`, `examples/explore-and-plan`, `examples/image-pipeline-skill`)**: **NOT VERIFIED** — classified as `SKIP(live)` and not executed headless.
- **Runtime execution of all `Makefile` targets (`make test`, `make coverage`, `make pv`, `make gate`)**: **NOT VERIFIED** (shell command execution was prohibited in this session).
- **`scripts/record-ready.sh` and `c04` `pv` / `contracts/`**: **NOT FOUND** and **NOT VERIFIED** in this repository worktree.
- **`.github/scripts/check-readme-consistency.sh`**: **NOT VERIFIED** by execution (checked by inspection that `Makefile` and `RECEIPTS.md` under `courses/c02-antigravity-internals/` are not under `examples/*/` and are not `README.md` files).
