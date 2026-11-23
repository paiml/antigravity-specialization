# Test-Driven Agentic Development with Google Antigravity: demo code

Companion code for the LinkedIn Learning course "Test-Driven Agentic Development with Google Antigravity".
Every demo is shell: a tiny test-first `slugify` CLI, the tests around it, and the checks that tell you
whether an agent's change can be trusted. The terminal lessons drive the `agy` CLI (pinned to 1.5.10).

## Run a lesson

```bash
./c2l2-make-it-pass/run.sh      # one lesson
make gate                       # no-Python check, bashrs lint, key scan, offline tests (no agent needed)
make coverage                   # line coverage of the shell code (xtrace based, approximate)
make pv                         # validate contracts/slugify-v1.yaml with the pv binary
scripts/capture.sh c2l2-make-it-pass   # save real output to captures/
```

Each lesson ends with `LESSON-STATUS: RUNS | BLOCKED-quota | BLOCKED-auth | SCRIPTED-NOT-RUN | FAILED`.
When the agent cannot run (quota or login), the lesson still runs its checks against a hand-written
reference solution and labels that output "NOT agent output". The tool never attempts a login.

## Lessons

| Dir | Topic |
|---|---|
| c1l0-why-agents-need-tests | agents that pass by changing the tests |
| c1l1-red-green-refactor | the loop on slugify |
| c1l2-setup | agy version pin, models, opening the project (UI step) |
| c1l3-spec-then-tests | agent writes tests from the spec |
| c1l4-read-the-plan | check an agent plan before it edits |
| c2l1-failing-test-first | agent writes a failing test, source untouched |
| c2l2-make-it-pass | agent makes it pass, tests untouched |
| c2l3-refactor-under-green | refactor with the tests as the referee |
| c2l4-catch-the-cheat | detect an agent that edited the tests |
| c2l5-coverage-gate | line coverage as a gate |
| c3l1-spec-the-agent-cannot-misread | numbered rules with examples |
| c3l2-contract-tests | YAML contract cases against the implementation |
| c3l3-property-tests | seeded random properties |
| c3l4-mutation-testing | seven deliberate bugs the suite must catch |
| c3l5-fan-out | several candidates, keep the one that verifies |
| c4l1-hooks-and-rules | AGENTS.md and a pre-commit hook |
| c4l2-ci-as-referee | the same gate in CI |
| c4l3-scheduled-task | a recurring agent task with a gate |
| c4l4-review-agent-change | first mechanical checks of a change |
| c4l5-template-repo | the project as a template |

See DEMO-STATUS.md for what ran, what was blocked, and which receipts exist.

## Hygiene

No secrets, no Python, no network needed for `make gate`. `tests/fake-agy` is a test-only stand-in and is
never used to produce course output. Scratch work goes under `.run/` (git-ignored) and is never deleted by the demos.

MIT licensed.
