# DEMO-STATUS

Measured 2026-11-17, `apr 0.74.0 (3795072634)`, CPU inference (`--no-gpu --offline`). Public repo: `paiml/responsible-genai-local-llms`.

## Local models used

Lessons 1.2 to 4.4 use `qwen-1.5b-q4k.apr` (1.0 GB, Qwen2 architecture, Q4_K, 1.78B parameters per `apr serve plan`). Its `apr inspect` provenance shows `license`, `data_source` and `data_license` all `(missing)` (lesson 3.5 demonstrates exactly that). Lesson 4.5 compares it with a 468 MB GGUF file (qwen2.5-0.5b-instruct, Q5_0), the smallest instruction-tuned model installed. Smaller files exist (gpt2 SafeTensors) but they are not instruction-following, so they make a poor drift probe.

## Per lesson

Capture files hold the real output with a header line (date, apr version, model) and the exit code. Model output is greedy (temperature 0) on small models, so quality is what you see in the capture.

| Lesson dir | Status | Capture | Note |
|---|---|---|---|
| c1l2-install-pull | RUNS (partial) | captures/c1l2-install-pull.out | `apr --version`, `apr list`, `apr pull --dry-run`, `apr inspect` ran. An actual `apr pull` download was NOT run; the dry-run resolves `qwen2.5-coder-1.5b` to `hf://Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF`. |
| c1l3-run | RUNS | captures/c1l3-run.out | `apr run <model> "What is 2+2?" --chat -n 24 --no-gpu --offline` answered "2 + 2 equals 4." |
| c1l4-serve-curl | RUNS | captures/c1l4-serve-curl.out | `/health`, `/v1/models`, `/v1/chat/completions` on 127.0.0.1:18931. A request without a `"model"` field returned "Invalid request body"; the demo sends `"model":"default"`. |
| c1l5-model-size | RUNS | captures/c1l5-model-size.out | `free -m`, file size, `apr serve plan`. The plan assumes the capture machine's GPU; the demo itself runs on CPU. |
| c2l1-prompt-basics | RUNS | captures/c2l1-prompt-basics.out | |
| c2l2-cli-chatbot | RUNS | captures/c2l2-cli-chatbot.out | Fed by `input.txt`; the bot remembers the name. |
| c2l3-summarize | RUNS | captures/c2l3-summarize.out | |
| c2l4-rag | RUNS | captures/c2l4-rag.out | Keyword retrieval, not embeddings. |
| c2l5-json-validate | RUNS | captures/c2l5-json-validate.out | Valid on attempt 1 (the script strips a code fence). The retry path is exercised only by the offline test with a bad stub. |
| c2l6-tokens-per-sec | RUNS | captures/c2l6-tokens-per-sec.out | About 28 to 29 tok/s through the server. `apr bench` was NOT run, only help-checked. |
| c3l1-hallucination | RUNS | captures/c3l1-hallucination.out | Without a source the model invented a name and year; the check flagged it. With the source it was right. |
| c3l2-bias-probes | RUNS | captures/c3l2-bias-probes.out | Six names. One run at temperature 0 is an illustration, not a statistical finding. |
| c3l3-prompt-injection | RUNS | captures/c3l3-prompt-injection.out | Attack succeeded; scan found the line; stripped and fenced version summarized correctly. |
| c3l4-secrets | RUNS | captures/c3l4-secrets.out | Secrets in the sample log are made up. |
| c3l5-model-cards | RUNS | captures/c3l5-model-cards.out | Reads `apr inspect` provenance. The upstream model card web page is not fetched. |
| c3l6-guardrails | RUNS | captures/c3l6-guardrails.out | One answered, one topic refusal, one sensitive-data refusal; log holds redacted prompts. |
| c4l1-eval-set | RUNS | captures/c4l1-eval-set.out | 4/5 = 80% against a 60% gate; the failure is real model output. |
| c4l2-audit-trail | RUNS | captures/c4l2-audit-trail.out | Limit: a hash chain detects edits of any line except the last one. |
| c4l3-sensitivity-router | RUNS (partial) | captures/c4l3-sensitivity-router.out | Local route ran. The hosted route is a printed stub: no hosted call, no credentials. |
| c4l4-checklist | RUNS | captures/c4l4-checklist.out | No model; checks this repo's own files. |
| c4l5-model-drift | RUNS | captures/c4l5-model-drift.out | Six fixed probes on two model files; 4 of 6 answers unchanged, 2 drifted. |

Totals: 21 demo scripts RUN (2 partial: c1l2 download, c4l3 hosted side), 0 scripted-not-run, 0 blocked. The course outline has 24 videos; the other 3 are talk or wrap-up videos with no demo script, so this is 21 of 24 outline videos with a demo, not 24 of 24.

## Gates run locally

- `make gate`: no Python, bashrs lint (0 errors), offline tests, grep leak scan, shell line coverage.
- Lint: 0 errors, 86 warnings (mostly PERF002, SC2086, SC2140, SC2295). `scripts/gate-lint.sh` gates on errors only.
- Coverage: no shell coverage tool is installed that works on this test suite (`bashrs coverage` counts only `test_*` functions). `scripts/coverage-trace.sh` is a hand-built bash xtrace tracer: it compares the executable lines hit by `tests/run-tests.sh` against an awk-derived list of executable lines. It is a line trace count, not an industry coverage tool, and it does not measure branch coverage.
- Leak scan: `scripts/gate-leaks.sh` is grep patterns for key shapes, local paths and internal names. It is NOT gitleaks, which was not installed on the capture machine; CI runs gitleaks.
- `pv`: `pv census` finds 0 contracts, because this repo ships no contract or ontology files; there is nothing for `pv validate` or `pv ontology` to check.
