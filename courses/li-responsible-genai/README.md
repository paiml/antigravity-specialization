# Responsible Generative AI and Local LLMs: terminal demos

Runnable terminal demos for the course *Responsible Generative AI and Local LLMs* by Pragmatic AI Labs. Every demo is a shell script that talks to a model running on your own machine through the aprender `apr` CLI. Nothing is sent to a hosted service.

Intended use: teaching and testing of local-model safety techniques. The demos and the small local models they use must not be used for medical, legal, hiring or other decisions about people; the sample "patient", "salary" and name data is made up.

## What the course is

A hands-on course in four chapters, all in the terminal:

1. Why run models locally, and what can go wrong: install `apr`, pull and run a model, serve it on localhost, pick a size that fits.
2. Building with a local model: prompts, a CLI chatbot, summarizing a document locally, small RAG, checked JSON output, tokens per second.
3. Bias, safety and privacy, tested in the terminal: hallucination checks, bias probes, prompt injection, secrets, model cards, guardrails as code.
4. Putting it to work responsibly: an evaluation set with a ship gate, a human check with an audit trail, routing by sensitivity, a checklist you can commit, and a model-drift re-check.

## Prerequisites

- A Linux or macOS terminal with `bash`, `curl`, `jq`, `awk`, `sed` and `sha256sum`.
- The `apr` CLI, version 0.74.0 or newer. Its own help text names the crate: install it with `cargo install aprender`, then confirm with `apr --version`.
- At least one local model. `apr pull <model>` downloads and caches one (`apr pull --dry-run <model>` shows what a name resolves to without downloading), and `apr list` shows what is cached.
- The demos default to `~/.cache/pacha/models/qwen-1.5b-q4k.apr`. Set `DEMO_MODEL` to any model file from `apr list` to use another one.

## Run a lesson

```bash
scripts/serve.sh                  # starts apr serve on 127.0.0.1:18931
c2l3-summarize/run.sh             # any lesson that needs the server
scripts/stop.sh
```

`c1l2-install-pull`, `c1l3-run`, `c1l5-model-size`, `c3l5-model-cards`, `c4l4-checklist` and `c4l5-model-drift` need no server.

## Lessons

| Lesson | Run command | What it shows |
|---|---|---|
| 1.2 Install apr and pull a model | `c1l2-install-pull/run.sh` | version, cache, pull dry-run, inspect |
| 1.3 Run a model in the terminal | `c1l3-run/run.sh` | one `apr run` call, CPU only |
| 1.4 Serve on localhost, call with curl | `c1l4-serve-curl/run.sh` | `/health`, `/v1/models`, chat completions |
| 1.5 Pick a model size | `c1l5-model-size/run.sh` | memory, file size, `apr serve plan` |
| 2.1 System, user and constraints | `c2l1-prompt-basics/run.sh` | the same question three ways |
| 2.2 A small CLI chatbot | `c2l2-cli-chatbot/run.sh < c2l2-cli-chatbot/input.txt` | chat with history |
| 2.3 Summarize a local file | `c2l3-summarize/run.sh` | no upload |
| 2.4 Small RAG on local text | `c2l4-rag/run.sh "your question"` | keyword retrieval, refuses to guess |
| 2.5 Structured output and validation | `c2l5-json-validate/run.sh` | `jq -e` schema check, retry |
| 2.6 Tokens per second | `c2l6-tokens-per-sec/run.sh` | speed on your hardware |
| 3.1 Hallucination source check | `c3l1-hallucination/run.sh` | flags names and numbers the source lacks |
| 3.2 Same prompt, different names | `c3l2-bias-probes/run.sh` | an illustration, not a statistic |
| 3.3 Prompt injection | `c3l3-prompt-injection/run.sh` | attack, scan, strip and fence |
| 3.4 Secrets out of prompts and logs | `c3l4-secrets/run.sh` | redaction and a leak check |
| 3.5 Read provenance before you run | `c3l5-model-cards/run.sh` | license and data fields |
| 3.6 Guardrails as code | `c3l6-guardrails/run.sh` | refuse, filter, log |
| 4.1 A test set with a ship gate | `c4l1-eval-set/run.sh` | pass-rate gate |
| 4.2 Human check and audit trail | `c4l2-audit-trail/run.sh < c4l2-audit-trail/data/decisions.txt` | hash-chained log, tamper check |
| 4.3 Route by sensitivity | `c4l3-sensitivity-router/run.sh` | local vs hosted (hosted side is a stub) |
| 4.4 A checklist you can commit | `c4l4-checklist/run.sh` | checks this repo's own files |
| 4.5 Model drift re-check | `c4l5-model-drift/run.sh` | same probes on two model files, diff the answers |

Lesson 4.5 compares two models, set with `MODEL_A` and `MODEL_B` (defaults: the 1.5B model above and a 0.5B instruct model). Edit `c4l5-model-drift/data/probes.txt` to use your own probes.

`captures/` holds the real output of each lesson from one run on one machine, with the date and `apr` version in the first line. Model output is greedy (temperature 0) on small models, so quality is what you see there, not what a larger model would give. `DEMO-STATUS.md` records, per lesson, what ran and what did not.

## Exercise files

- `exercises/labs.md`: four labs (install and serve; local RAG; bias and injection probes; evaluation set and drift).
- `exercises/readings.md`: four short readings.
- The lesson folders' `data/` directories hold the sample inputs the labs ask you to edit.

## Checks

`make gate` runs the checks CI runs, with no model and no network:

- `scripts/gate-nopython.sh`: no Python anywhere.
- `scripts/gate-lint.sh`: `bashrs lint` over every shell script.
- `tests/run-tests.sh`: offline tests that stand in for `apr` and `curl`; the checks that can go red are tested going red.
- `scripts/gate-leaks.sh`: grep patterns for key shapes and local paths (not gitleaks).
- `scripts/coverage-trace.sh 100`: line coverage of the shell code by those tests, measured with bash xtrace.

`make gate-secrets` runs gitleaks (CI installs a pinned binary).

## License

MIT, see `LICENSE`.
