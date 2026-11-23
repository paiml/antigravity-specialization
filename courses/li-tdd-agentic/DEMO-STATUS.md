# DEMO-STATUS

Recorded 2026-11-17. agy 1.5.10 installed (the brief said 1.5.9; the CLI updated itself, and 1.5.10 changed
`--print` to need its prompt attached as `--print=PROMPT`, which the demos use). Authentication: logged in.
Quota: exhausted, "Individual quota reached ... Resets in 94h42m" (RESOURCE_EXHAUSTED, 429). Every live agent
turn is therefore BLOCKED-quota. No login was attempted.

Totals: RUNS 13, BLOCKED-quota 6, SCRIPTED-NOT-RUN 1, FAILED 0. The outline lists 22 videos including 4 quizzes; this repo has 20 lesson dirs.

| Lesson | Status | Type | Capture | Notes |
|---|---|---|---|---|
| c1l0-why-agents-need-tests | RUNS | terminal | captures/c1l0-why-agents-need-tests.out | |
| c1l1-red-green-refactor | RUNS | terminal | captures/c1l1-red-green-refactor.out | |
| c1l2-setup | RUNS | MIXED | captures/c1l2-setup.out | UI step: open `project/` in Antigravity (repo state to open) |
| c1l3-spec-then-tests | BLOCKED-quota | terminal | captures/c1l3-spec-then-tests.out | reference check ran, labeled NOT agent output |
| c1l4-read-the-plan | SCRIPTED-NOT-RUN | MIXED | captures/c1l4-read-the-plan.out | the plan artifact is an Antigravity UI view; agent turn blocked by quota; plan-check ran on hand-written plans |
| c2l1-failing-test-first | BLOCKED-quota | terminal | captures/c2l1-failing-test-first.out | reference check ran |
| c2l2-make-it-pass | BLOCKED-quota | terminal | captures/c2l2-make-it-pass.out | reference check ran |
| c2l3-refactor-under-green | BLOCKED-quota | terminal | captures/c2l3-refactor-under-green.out | reference check ran |
| c2l4-catch-the-cheat | RUNS | terminal | captures/c2l4-catch-the-cheat.out | |
| c2l5-coverage-gate | RUNS | terminal | captures/c2l5-coverage-gate.out | |
| c3l1-spec-the-agent-cannot-misread | RUNS | terminal | captures/c3l1-spec-the-agent-cannot-misread.out | |
| c3l2-contract-tests | RUNS | terminal | captures/c3l2-contract-tests.out | |
| c3l3-property-tests | RUNS | terminal | captures/c3l3-property-tests.out | |
| c3l4-mutation-testing | RUNS | terminal | captures/c3l4-mutation-testing.out | |
| c3l5-fan-out | BLOCKED-quota | terminal | captures/c3l5-fan-out.out | reference check ran |
| c4l1-hooks-and-rules | RUNS | terminal | captures/c4l1-hooks-and-rules.out | plain git hook; Antigravity hook config not verified |
| c4l2-ci-as-referee | RUNS | MIXED | captures/c4l2-ci-as-referee.out | local gate ran; hosted CI run not done (repo not pushed) |
| c4l3-scheduled-task | BLOCKED-quota | terminal | captures/c4l3-scheduled-task.out | reference check ran |
| c4l4-review-agent-change | RUNS | MIXED | captures/c4l4-review-agent-change.out | mechanical checks ran; the pull request page is a UI |
| c4l5-template-repo | RUNS | terminal | captures/c4l5-template-repo.out | |

## Receipts

- `make gate`: green (no-Python check: 0 python files; bashrs lint --level error: 48 shell files, 0 errors; key/internal-word scan: 0; offline tests: 134 passed, 0 failed).
- Coverage: 436/458 shell lines = 95.2% (xtrace line coverage, approximate). NOT 100%. Missed: scripts/verify.sh 19-20, scripts/contract-test.sh 7-12, scripts/cov.sh 9,11-17, project/tests/property.sh 24-25, c2l5 run.sh 5 and 24, c3l2 run.sh 12, c4l1 run.sh 21-22 (mostly usage/error branches).
- pv: `pv validate contracts/slugify-v1.yaml` gave 0 errors, 0 warnings.
- Key-pattern scan: scripts/gate-scan.sh (gitleaks is absent).

## Missing receipts

- Hosted CI run: none (repo not pushed).
- Coverage is below 100%.
- probar end-to-end: not applicable to the shell lessons; the Antigravity UI steps (c1l2, c1l4, c4l2, c4l4) were not driven.
- Live agent prompts in accept-edits mode are unverified because quota is exhausted; prompts in prompts/ are untested against a real agent.
- Antigravity hook configuration was not verified.
