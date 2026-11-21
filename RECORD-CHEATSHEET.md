# Recording Cheatsheet — Antigravity Specialization

- **Git SHA (worktree HEAD `agy-record-ready-antigravity-specialization`)**: `c29d8a2a15a5107bd76afb32946dd8cde73319f6` (`antigravity-specialization@c29d8a2`)
- **Git SHA (`main` / `origin/main`)**: `c29d8a2a15a5107bd76afb32946dd8cde73319f6`
- **Verification Policy**: No command was guessed. Every command below is marked with:
  - `RAN` (from the fresh `kfocus` `scripts/record-ready.sh` run at `antigravity-specialization@c29d8a2`),
  - `READ <file:line>` (directly read from the repository files in this worktree), and/or
  - `NOT VERIFIED` (live-only, skipped, blocked before execution, or not run on `kfocus`).
- **Course Coverage Note**: `c03` is present (`READ specialization.toml:13-17`, `courses/c03-verifying-agent-work/course.toml`): 20 examples, 20 `verify.sh`; a fresh run of every `verify.sh` exited 0 and printed its `contract: <name> OK` line (17 offline-only, 3 live at recording). `scripts/record-ready.sh` does not sweep `c03` (it covers `c01`, `c02`, `c04`), so the `c03` proof below is the direct `verify.sh` run, not the sweep.

## Per-Chapter Recording Status (`antigravity-specialization@c29d8a2`)

| chapter | recordable yes/no | proof | blocker |
|---|---|---|---|
| `c01/complex-image-processing` | yes | `RAN` on `kfocus` 2026-11-21 (`c29d8a2`, `scripts/record-ready.sh`, ImageMagick 7.1.2): `PASS`; `READ courses/c01-the-antigravity-platform/examples/complex-image-processing/example.toml:7-8`, `remove_star.sh:15` | none |
| `c02/grill-me-first` | live | `RAN` on `kfocus` (`c29d8a2`, `scripts/record-ready.sh`): `SKIP(live)`; `READ courses/c02-antigravity-internals/examples/grill-me-first/example.toml:7-8`, `grill.sh:22` | LIVE AT RECORDING per Noah ruling 2026-11-21; not a blocker; Noah confirms the prompt on camera (live interactive `agy -i` session required) |
| `c02/explore-and-plan` | live | `RAN` on `kfocus` (`c29d8a2`, `scripts/record-ready.sh`): `SKIP(live)`; `RAN` live 2026-11-21 twice (`agy -p ... --mode plan`) returned only a preamble sentence and no answer (`LIVE-explore-and-plan-2026-11-21.txt`); `READ courses/c02-antigravity-internals/examples/explore-and-plan/example.toml:7-8`, `explore.sh:16`, `plan.sh:15` | LIVE AT RECORDING per Noah ruling 2026-11-21; not a blocker; Noah confirms the prompt on camera (earlier headless explore run returned only a preamble sentence and no answer; plan mode headless appears to deny tools) |
| `c02/transpose-image` | yes | `RAN` on `kfocus` 2026-11-21 (`c29d8a2`, `scripts/record-ready.sh`, ImageMagick 7.1.2): `PASS`; `READ courses/c02-antigravity-internals/examples/transpose-image/example.toml:7-8`, `transpose.sh:27-36` | none |
| `c02/image-pipeline` | yes | `RAN` on `kfocus` 2026-11-21 (`c29d8a2`, `scripts/record-ready.sh`, ImageMagick 7.1.2): `PASS`; `READ courses/c02-antigravity-internals/examples/image-pipeline/example.toml:7-8`, `verify.sh:18-29` | none |
| `c02/image-pipeline-skill` | yes | `RAN` live 2026-11-21 via `agy -p 'use the image-pipeline skill on pyramid-star.png'` (model `gemini-4-hydrogen-high`): output "Transposed 502x460 -> 460x502", `verify.sh` "OK -- 3 checks passed" (`LIVE-image-pipeline-skill-2026-11-21.txt`); `kfocus` `scripts/record-ready.sh`: `SKIP(live)`; `READ courses/c02-antigravity-internals/examples/image-pipeline-skill/example.toml:7-8` | none |
| `c02/batch-runner` | yes | `RAN` on `kfocus` 2026-11-21 (`c29d8a2`, `scripts/record-ready.sh`, ImageMagick 7.1.2): `PASS`; `READ courses/c02-antigravity-internals/examples/batch-runner/example.toml:7-8`, `scripts/record-ready.sh:153-163` | none |
| `c02/pmat-review-agent` | yes | `RAN` on `kfocus` (`c29d8a2`, `scripts/record-ready.sh`): `PASS` (`./verify.sh`); `READ courses/c02-antigravity-internals/examples/pmat-review-agent/example.toml:7`, `verify.sh:1-48` | None for `./verify.sh` (live `agy agents` install step is `NOT VERIFIED`) |
| `c03/m*` (17 offline examples, see Course 3) | yes | `RAN` 2026-11-21 (`c9b16ff`): each `bash ./verify.sh` exit 0, prints `contract: <example> OK`; `READ courses/c03-verifying-agent-work/course.toml` | none |
| `c03/m2-create-first-agent` | live | `RAN` 2026-11-21 (`c9b16ff`): offline `bash ./verify.sh` exit 0, `contract: m2-create-first-agent OK`; `./run-agent.sh` is live `agy`, `NOT VERIFIED`; `READ courses/c03-verifying-agent-work/examples/m2-create-first-agent/example.toml:9` | LIVE AT RECORDING (`Live: needs agy.`); not a blocker |
| `c03/m2-getting-started-antigravity` | live | `RAN` 2026-11-21 (`c9b16ff`): offline `bash ./verify.sh` exit 0, `contract: m2-getting-started-antigravity OK`; `./explore-workspace.sh` is live `agy`, `NOT VERIFIED`; `READ courses/c03-verifying-agent-work/examples/m2-getting-started-antigravity/example.toml:9` | LIVE AT RECORDING (`Live: needs agy.`); not a blocker |
| `c03/m6-antigravity-analysis` | live | `RAN` 2026-11-21 (`c9b16ff`): offline `bash ./verify.sh` exit 0, `contract: m6-antigravity-analysis OK`; `./analyze.sh` is live `agy`, `NOT VERIFIED`; `READ courses/c03-verifying-agent-work/examples/m6-antigravity-analysis/example.toml:9` | LIVE AT RECORDING (`Live: needs agy.`); not a blocker |
| `c04/m1` | yes | `RAN` on `kfocus` (`c29d8a2`, `scripts/record-ready.sh`): `PASS` (`gate.sh m1`); `READ c04-falsify-the-agent/scripts/gate.sh:15-101`, `c04-falsify-the-agent/m1/contracts/test-floor-v1.yaml:1-36` | None |
| `c04/m2` | yes | `RAN` on `kfocus` (`c29d8a2`, `scripts/record-ready.sh`): `PASS` (`gate.sh m2`); `READ c04-falsify-the-agent/scripts/gate.sh:15-101`, `c04-falsify-the-agent/m2/contracts/kill-rate-v1.yaml:1-32` | None |
| `c04/m3` | yes | `RAN` on `kfocus` (`c29d8a2`, `scripts/record-ready.sh`): `PASS` (`gate.sh m3`); `READ c04-falsify-the-agent/scripts/gate.sh:15-101`, `c04-falsify-the-agent/m3/contracts/clamp-v1.yaml:1-38` | None |
| `c04/m4` | yes | `RAN` on `kfocus` (`c29d8a2`, `scripts/record-ready.sh`): `PASS` (`gate.sh m4`); `READ c04-falsify-the-agent/scripts/gate.sh:15-101`, `c04-falsify-the-agent/m4/contracts/gate-floor-v1.yaml:1-30`, `referee-v1.yaml:1-30` | None |
| `c04/m5` | yes | `RAN` on `kfocus` (`c29d8a2`, `scripts/record-ready.sh`): `PASS` (`gate.sh m5`); `READ c04-falsify-the-agent/scripts/gate.sh:15-101`, `c04-falsify-the-agent/m5/contracts/record-ui-v1.yaml:1-36` | None (`m5/scripts/e2e.sh` is optional and `NOT VERIFIED`) |
| `c04/m6` | yes | `RAN` on `kfocus` (`c29d8a2`, `scripts/record-ready.sh`): `PASS` (`gate.sh m6`); `READ c04-falsify-the-agent/scripts/gate.sh:15-101`, `c04-falsify-the-agent/m6/contracts/discount-v1.yaml:1-36` | None |

---

## Live-at-recording prompts (exact; Noah confirms on camera)

- grill-me-first (`grill.sh:22`, interactive):
  ```bash
  agy -i "/grill-me add a transpose step to remove_star.sh"
  ```
- explore-and-plan rung 1 (`explore.sh:16`):
  ```bash
  agy -p 'Explain what this repository is for, how the courses and examples are laid out, and what enforces that layout. Do not change anything.' --mode plan
  ```
- explore-and-plan rung 2 (`plan.sh:15`):
  ```bash
  agy -p 'Plan adding a transpose step to remove_star.sh, using only ImageMagick and bash, no Python. Name every ImageMagick operator that could plausibly be meant by transpose, say how they differ, and say how I would tell them apart after the fact. Do not write any files.' --mode plan
  ```

---

## Pre-Flight Checks (Before Recording)

1. Verify the README consistency gate self-test (`NOT VERIFIED` / `READ .github/workflows/gate.yml:65`):
   ```bash
   .github/scripts/check-readme-consistency.sh --self-test
   ```
2. Verify all generated READMEs match their TOML sources (`NOT VERIFIED` / `READ .github/workflows/gate.yml:68`):
   ```bash
   .github/scripts/check-readme-consistency.sh
   ```
3. Verify the recording-readiness sweep self-test (`NOT VERIFIED` / `READ scripts/record-ready.sh:7,320-433`):
   ```bash
   bash scripts/record-ready.sh --self-test
   ```
4. Run the recording-readiness sweep across all chapters (`c01`, `c02`, and `c04/m1..m6`; `c03` is not in the sweep, run its `verify.sh` files directly) (`RAN` on `kfocus` 2026-11-21 at `antigravity-specialization@c29d8a2`, ImageMagick 7.1.2: `c01/complex-image-processing`, `c02/transpose-image`, `c02/image-pipeline`, `c02/batch-runner`, `c02/pmat-review-agent`, and `c04/m1..m6` `PASS` (`SWEEP-1700Z.txt`); `c02/grill-me-first`, `c02/explore-and-plan`, `c02/image-pipeline-skill` `SKIP(live)` (`NOT VERIFIED`); `READ scripts/record-ready.sh:5,243-318`):
   ```bash
   bash scripts/record-ready.sh
   ```

---

## Course 1 — The Antigravity Platform (`courses/c01-the-antigravity-platform`)

### Chapter `c01/complex-image-processing` — Complex image processing

1. Enter the example directory (`RAN` via `scripts/record-ready.sh:125` on `kfocus` at `c29d8a2` / `READ courses/c01-the-antigravity-platform/course.toml:12`):
   ```bash
   cd courses/c01-the-antigravity-platform/examples/complex-image-processing
   ```
2. Remove the star and its shadow from `pyramid-star.png` (`RAN` on `kfocus` at `c29d8a2` 2026-11-21: `PASS`, ImageMagick 7.1.2):
   ```bash
   ./remove_star.sh pyramid-star.png out.png
   ```

---

## Course 2 — Antigravity Internals (`courses/c02-antigravity-internals`)

### Chapter `c02/grill-me-first` — Interview before you plan

1. Enter the example directory (`NOT VERIFIED` — `SKIP(live)` in `scripts/record-ready.sh:132-135` / `READ courses/c02-antigravity-internals/course.toml:16`):
   ```bash
   cd courses/c02-antigravity-internals/examples/grill-me-first
   ```
2. Start the interactive `/grill-me` interview (`NOT VERIFIED` — `RAN` in `scripts/record-ready.sh` on `kfocus` at `c29d8a2` as `SKIP(live)`, interactive `agy -i "/grill-me $TASK"` only; `READ courses/c02-antigravity-internals/examples/grill-me-first/example.toml:7-8`, `README.md:8`, `grill.sh:22`):
   ```bash
   ./grill.sh
   ```

### Chapter `c02/explore-and-plan` — Explore and plan

1. Enter the example directory (`NOT VERIFIED` — `SKIP(live)` in `scripts/record-ready.sh:132-135` / `READ courses/c02-antigravity-internals/course.toml:21`):
   ```bash
   cd courses/c02-antigravity-internals/examples/explore-and-plan
   ```
2. Rung 1 — ask `agy` what the repository does in read-only plan mode (`NOT VERIFIED` — `RAN` in `scripts/record-ready.sh` on `kfocus` at `c29d8a2` as `SKIP(live)`, live `agy -p '...' --mode plan` only; `READ courses/c02-antigravity-internals/examples/explore-and-plan/example.toml:7-8`, `README.md:8`, `explore.sh:16`):
   ```bash
   ./explore.sh
   ```
3. Rung 2 — ask `agy` for a transpose implementation plan in read-only plan mode (`NOT VERIFIED` — live `agy -p '...' --mode plan` only, not invoked by `scripts/record-ready.sh`; `READ courses/c02-antigravity-internals/examples/explore-and-plan/README.md:11`, `plan.sh:15`):
   ```bash
   ./plan.sh
   ```

### Chapter `c02/transpose-image` — Transpose an image

1. Enter the example directory (`RAN` via `scripts/record-ready.sh:137` on `kfocus` at `c29d8a2` / `READ courses/c02-antigravity-internals/course.toml:26`):
   ```bash
   cd courses/c02-antigravity-internals/examples/transpose-image
   ```
2. Transpose `nostar.png` across the top-left/bottom-right diagonal (`RAN` on `kfocus` at `c29d8a2` 2026-11-21: `PASS`, ImageMagick 7.1.2):
   ```bash
   ./transpose.sh nostar.png out.png
   ```

### Chapter `c02/image-pipeline` — The whole pipeline in one script

1. Enter the example directory (`RAN` via `scripts/record-ready.sh:145` on `kfocus` at `c29d8a2` / `READ courses/c02-antigravity-internals/course.toml:31`):
   ```bash
   cd courses/c02-antigravity-internals/examples/image-pipeline
   ```
2. Run both stages (`remove_star.sh` + `transpose.sh`) and verify shape, involution, and non-rotation (`RAN` on `kfocus` at `c29d8a2` 2026-11-21 via `scripts/record-ready.sh`: `PASS`, ImageMagick 7.1.2):
   ```bash
   ./pipeline.sh pyramid-star.png out.png && ./verify.sh
   ```

### Chapter `c02/image-pipeline-skill` — The pipeline as a skill

1. Enter the example directory (`NOT VERIFIED` — `SKIP(live)` in `scripts/record-ready.sh:132-135` / `READ courses/c02-antigravity-internals/course.toml:36`):
   ```bash
   cd courses/c02-antigravity-internals/examples/image-pipeline-skill
   ```
2. Invoke the project-local `image-pipeline` skill via `agy` (`RAN` live 2026-11-21 via `agy -p 'use the image-pipeline skill on pyramid-star.png'` with model `gemini-4-hydrogen-high`: output "Transposed 502x460 -> 460x502", `verify.sh` "OK -- 3 checks passed" per `LIVE-image-pipeline-skill-2026-11-21.txt`; `kfocus` `scripts/record-ready.sh` at `c29d8a2` was `SKIP(live)`; `READ courses/c02-antigravity-internals/examples/image-pipeline-skill/example.toml:7-8`, `README.md:8`):
   ```bash
   agy -p 'use the image-pipeline skill on pyramid-star.png'
   ```

### Chapter `c02/batch-runner` — Batch the pipeline

1. Enter the example directory (`RAN` via `scripts/record-ready.sh:169` on `kfocus` (2026-11-21, `c29d8a2`): `PASS` — covered by whole-demo PASS in sweep; step not separately timed; `READ courses/c02-antigravity-internals/course.toml:41`):
   ```bash
   cd courses/c02-antigravity-internals/examples/batch-runner
   ```
2. Run the unit tests over template substitution (`RAN` via `scripts/record-ready.sh:170` on `kfocus` (2026-11-21, `c29d8a2`): `PASS` — covered by whole-demo PASS in sweep; step not separately timed; `READ courses/c02-antigravity-internals/examples/batch-runner/README.md:13`, `Cargo.toml:2`):
   ```bash
   cargo test -p batch-runner
   ```
3. Run the parallel batch runner over `images/` (`RAN` via `scripts/record-ready.sh:152-181` on `kfocus` (2026-11-21, `c29d8a2`, ImageMagick 7.1.2): `PASS` — covered by whole-demo PASS in sweep; step not separately timed; `READ courses/c02-antigravity-internals/examples/batch-runner/example.toml:7-8`, `Cargo.toml:2`, `README.md:8,11`, where `magick` substitutes for `convert` on ImageMagick 7):
   ```bash
   cargo run --bin batch-runner -- --dir images --cmd 'convert {} -transpose +repage {}.t.png'
   ```

### Chapter `c02/pmat-review-agent` — A review agent that runs pmat

1. Enter the example directory (`RAN` via `scripts/record-ready.sh:184` on `kfocus` at `c29d8a2` / `READ courses/c02-antigravity-internals/course.toml:46`):
   ```bash
   cd courses/c02-antigravity-internals/examples/pmat-review-agent
   ```
2. Run the headless `pmat` defect-planting verification loop (`RAN` on `kfocus` at `c29d8a2`: `PASS` via `scripts/record-ready.sh:184`; `READ courses/c02-antigravity-internals/examples/pmat-review-agent/example.toml:7`, `README.md:8`, `verify.sh:1-48`):
   ```bash
   ./verify.sh
   ```
3. (Live `agy` recording only) Install the agent globally and confirm registration (`NOT VERIFIED` — live `agy` only, not run by `scripts/record-ready.sh`; `READ courses/c02-antigravity-internals/examples/pmat-review-agent/README.md:17-18`):
   ```bash
   cp agents/pmat-review.md ~/.gemini/config/agents/
   agy agents
   ```

---

## Course 3 — Verifying AI Agent Work (`courses/c03-verifying-agent-work`)

20 examples across modules `m1..m6`, each with its own `verify.sh` (`READ courses/c03-verifying-agent-work/course.toml`). `RAN` 2026-11-21 at `antigravity-specialization@c9b16ff`: all 20 `verify.sh` exit 0 and print the `contract:` line shown; 17 are offline-only and 3 are flagged Live (`Live: needs agy.`), whose `verify.sh` still passes offline but whose run step needs `agy` at recording (`NOT VERIFIED`).

| # | example | verify command | printed line | live at recording |
|---|---|---|---|---|
| 1 | `m1-agentic-coding-evolution` | `cd courses/c03-verifying-agent-work/examples/m1-agentic-coding-evolution && bash ./verify.sh` | `contract: m1-agentic-coding-evolution OK` | no |
| 2 | `m1-llm-benefits-and-risks` | `cd courses/c03-verifying-agent-work/examples/m1-llm-benefits-and-risks && bash ./verify.sh` | `contract: m1-llm-benefits-and-risks OK` | no |
| 3 | `m1-what-is-generative-ai` | `cd courses/c03-verifying-agent-work/examples/m1-what-is-generative-ai && bash ./verify.sh` | `contract: m1-what-is-generative-ai OK` | no |
| 4 | `m2-antigravity-artifacts` | `cd courses/c03-verifying-agent-work/examples/m2-antigravity-artifacts && bash ./verify.sh` | `contract: m2-antigravity-artifacts OK` | no |
| 5 | `m2-create-first-agent` | `cd courses/c03-verifying-agent-work/examples/m2-create-first-agent && bash ./verify.sh` | `contract: m2-create-first-agent OK` | yes: `./run-agent.sh` needs `agy` (`NOT VERIFIED`) |
| 6 | `m2-getting-started-antigravity` | `cd courses/c03-verifying-agent-work/examples/m2-getting-started-antigravity && bash ./verify.sh` | `contract: m2-getting-started-antigravity OK` | yes: `./explore-workspace.sh` needs `agy` (`NOT VERIFIED`) |
| 7 | `m3-mitigating-risks-of-llms` | `cd courses/c03-verifying-agent-work/examples/m3-mitigating-risks-of-llms && bash ./verify.sh` | `contract: m3-mitigating-risks-of-llms OK` | no |
| 8 | `m3-the-verification-ladder` | `cd courses/c03-verifying-agent-work/examples/m3-the-verification-ladder && bash ./verify.sh` | `contract: m3-the-verification-ladder OK` | no |
| 9 | `m3-when-agents-fail` | `cd courses/c03-verifying-agent-work/examples/m3-when-agents-fail && bash ./verify.sh` | `contract: m3-when-agents-fail OK` | no |
| 10 | `m3-which-languages-suit-agentic-coding` | `cd courses/c03-verifying-agent-work/examples/m3-which-languages-suit-agentic-coding && bash ./verify.sh` | `contract: m3-which-languages-suit-agentic-coding OK` | no |
| 11 | `m4-simplifying-rules-with-automation` | `cd courses/c03-verifying-agent-work/examples/m4-simplifying-rules-with-automation && bash ./verify.sh` | `contract: m4-simplifying-rules-with-automation OK` | no |
| 12 | `m4-using-advanced-verification-with-pmat` | `cd courses/c03-verifying-agent-work/examples/m4-using-advanced-verification-with-pmat && bash ./verify.sh` | `contract: m4-using-advanced-verification-with-pmat OK` | no |
| 13 | `m4-using-test-driven-development` | `cd courses/c03-verifying-agent-work/examples/m4-using-test-driven-development && bash ./verify.sh` | `contract: m4-using-test-driven-development OK` | no |
| 14 | `m5-ci-verifying-agent-work` | `cd courses/c03-verifying-agent-work/examples/m5-ci-verifying-agent-work && bash ./verify.sh` | `contract: m5-ci-verifying-agent-work OK` | no |
| 15 | `m5-components-of-a-job` | `cd courses/c03-verifying-agent-work/examples/m5-components-of-a-job && bash ./verify.sh` | `contract: m5-components-of-a-job OK` | no |
| 16 | `m5-dockerfile-linting` | `cd courses/c03-verifying-agent-work/examples/m5-dockerfile-linting && bash ./verify.sh` | `contract: m5-dockerfile-linting OK` | no |
| 17 | `m5-github-actions-intro` | `cd courses/c03-verifying-agent-work/examples/m5-github-actions-intro && bash ./verify.sh` | `contract: m5-github-actions-intro OK` | no |
| 18 | `m5-why-ci-is-the-referee` | `cd courses/c03-verifying-agent-work/examples/m5-why-ci-is-the-referee && bash ./verify.sh` | `contract: m5-why-ci-is-the-referee OK` | no |
| 19 | `m6-anatomy-of-a-verified-repo` | `cd courses/c03-verifying-agent-work/examples/m6-anatomy-of-a-verified-repo && bash ./verify.sh` | `contract: m6-anatomy-of-a-verified-repo OK` | no |
| 20 | `m6-antigravity-analysis` | `cd courses/c03-verifying-agent-work/examples/m6-antigravity-analysis && bash ./verify.sh` | `contract: m6-antigravity-analysis OK` | yes: `./analyze.sh` needs `agy` (`NOT VERIFIED`) |

Every row is `RAN` (exit 0, line printed). Live rows: only the example's own run script needs `agy`.


---

## Course 4 — Falsify the Agent (`c04-falsify-the-agent`)

Course 4 modules live under `c04-falsify-the-agent/m1..m6` (each its own Cargo workspace with its own `Cargo.lock` per `READ c04-falsify-the-agent/scripts/gate.sh:5`). `scripts/record-ready.sh` runs each module's offline gate via `bash c04-falsify-the-agent/scripts/gate.sh mN` (`RAN` on `kfocus` at `c29d8a2`: `c04/m1..m6` `PASS`; requires `cargo`, `rustfmt`, and `pv` per `READ c04-falsify-the-agent/scripts/gate.sh:15`).

- **Course-wide gate and coverage** (`NOT VERIFIED` — `scripts/record-ready.sh` runs per-module `gate.sh mN`, not `make gate` or `coverage.sh`; `READ c04-falsify-the-agent/Makefile:2-6`, `.github/workflows/c04-falsify-the-agent.yml:61-68`, `c04-falsify-the-agent/scripts/coverage.sh:13`):
  ```bash
  cd c04-falsify-the-agent && make gate
  ```

### Chapter `c04/m1` — Module `m1` (`c04-falsify-the-agent/m1`)

1. Run `m1` offline gate (fmt, clippy, tests, demo bins, `pv` contract `test-floor-v1.yaml` and cited falsification tests) (`RAN` on `kfocus` at `c29d8a2`: `PASS` via `scripts/record-ready.sh:233`; `READ c04-falsify-the-agent/scripts/gate.sh:3-4,26-98`, `c04-falsify-the-agent/m1/contracts/test-floor-v1.yaml:1-36`):
   ```bash
   bash c04-falsify-the-agent/scripts/gate.sh m1
   ```

### Chapter `c04/m2` — Module `m2` (`c04-falsify-the-agent/m2`)

1. Run `m2` offline gate (fmt, clippy, tests, demo bins, `pv` contract `kill-rate-v1.yaml` and cited falsification tests) (`RAN` on `kfocus` at `c29d8a2`: `PASS` via `scripts/record-ready.sh:233`; `READ c04-falsify-the-agent/scripts/gate.sh:3-4,26-98`, `c04-falsify-the-agent/m2/contracts/kill-rate-v1.yaml:1-32`):
   ```bash
   bash c04-falsify-the-agent/scripts/gate.sh m2
   ```

### Chapter `c04/m3` — Module `m3` (`c04-falsify-the-agent/m3`)

1. Run `m3` offline gate (fmt, clippy, tests, demo bins, `pv` contract `clamp-v1.yaml` and cited falsification tests) (`RAN` on `kfocus` at `c29d8a2`: `PASS` via `scripts/record-ready.sh:233`; `READ c04-falsify-the-agent/scripts/gate.sh:3-4,26-98`, `c04-falsify-the-agent/m3/contracts/clamp-v1.yaml:1-38`):
   ```bash
   bash c04-falsify-the-agent/scripts/gate.sh m3
   ```

### Chapter `c04/m4` — Module `m4` (`c04-falsify-the-agent/m4`)

1. Run `m4` offline gate (fmt, clippy, tests, demo bins, `pv` contracts `gate-floor-v1.yaml` & `referee-v1.yaml` and cited falsification tests) (`RAN` on `kfocus` at `c29d8a2`: `PASS` via `scripts/record-ready.sh:233`; `READ c04-falsify-the-agent/scripts/gate.sh:3-4,26-98`, `c04-falsify-the-agent/m4/contracts/gate-floor-v1.yaml:1-30`, `c04-falsify-the-agent/m4/contracts/referee-v1.yaml:1-30`):
   ```bash
   bash c04-falsify-the-agent/scripts/gate.sh m4
   ```

### Chapter `c04/m5` — Module `m5` (`c04-falsify-the-agent/m5`)

1. Run `m5` offline gate (fmt, clippy, tests, demo bins, `pv` contract `record-ui-v1.yaml` and cited falsification tests) (`RAN` on `kfocus` at `c29d8a2`: `PASS` via `scripts/record-ready.sh:233`; `READ c04-falsify-the-agent/scripts/gate.sh:3-4,26-98`, `c04-falsify-the-agent/m5/contracts/record-ui-v1.yaml:1-36`; optional wasm/headless-Chrome e2e in `c04-falsify-the-agent/m5/scripts/e2e.sh:1-21` is `NOT VERIFIED` / `READ c04-falsify-the-agent/m5/scripts/e2e.sh:1-21`):
   ```bash
   bash c04-falsify-the-agent/scripts/gate.sh m5
   ```

### Chapter `c04/m6` — Module `m6` (`c04-falsify-the-agent/m6`)

1. Run `m6` offline gate (fmt, clippy, tests, demo bins, `pv` contract `discount-v1.yaml` and cited falsification tests) (`RAN` on `kfocus` at `c29d8a2`: `PASS` via `scripts/record-ready.sh:233`; `READ c04-falsify-the-agent/scripts/gate.sh:3-4,26-98`, `c04-falsify-the-agent/m6/contracts/discount-v1.yaml:1-36`):
   ```bash
   bash c04-falsify-the-agent/scripts/gate.sh m6
   ```
