# DEMO-STATUS

Measured 2026-11-17 with Node v22.13.1 (nvm), `agy` 1.5.10, Docker Engine 29.8.1, `bashrs` 7.4.3, `pv` 0.74.0. Public repo to be: `paiml/fullstack-antigravity-agents`. Nothing here has been pushed.

## What the three statuses mean

- **RUNS**: the script ran for real and `captures/<lesson>.out` holds the real output, with the exit code on the last line.
- **SCRIPTED-NOT-RUN**: the step is written down but was not run (no browser, no real SSH host, no pull request).
- **BLOCKED**: the step needs the Antigravity CLI and it refused. `agy --print=...` answered `RESOURCE_EXHAUSTED (code 429): Individual quota reached ... Resets in 91h` on 2026-11-17 (a probe, then every lesson capture). Nobody logged in and no credential was typed. The scripts print an `AGY-BLOCKED` line and continue; no agent output is invented. The text each agent step sends is committed under `<lesson>/prompts/`.

Every lesson has the same shape: the agent step (BLOCKED while there is no quota) followed by a checkpoint step that verifies the committed milestone state with real commands (RUNS).

## Per lesson

| Lesson dir | Status | Notes |
|---|---|---|
| c1l0-what-we-build | RUNS + browser SCRIPTED-NOT-RUN | Finished app started on a free port, API walked with curl. Opening the page in a browser is a `BROWSER STEP` line. |
| c1l1-spec | RUNS checkpoint, agent BLOCKED | Spec lint passes the real SPEC.md and rejects a spec with a section removed (the printed `FAIL missing section: Acceptance` is that deliberate rejection). |
| c1l2-context | RUNS checkpoint, agent BLOCKED | CONTEXT.md shown and checked; `agy --version` ran. |
| c1l3-architecture-review | RUNS checkpoint, agent BLOCKED | ARCHITECTURE.md checked against the real routes. |
| c1l4-stack-check | RUNS checkpoint, agent BLOCKED | Node and `node:sqlite` version probe, DECISIONS.md. |
| c1l5-scaffold-commit | RUNS checkpoint, agent BLOCKED | `make ci` on the ch1 scaffold, first commit and tag in a scratch repo. |
| c2l1-migrations | RUNS checkpoint, agent BLOCKED | Migrations applied with `sqlite3` and with the app. |
| c2l2-api-tdd | RUNS checkpoint, agent BLOCKED | Real red run (7 of 9 API tests fail against the ch1 server), then green on ch2. The agent's edit between the two is what is BLOCKED. |
| c2l3-auth | RUNS checkpoint, agent BLOCKED | curl 401 without and with a wrong token, 201 with the right one; production refuses to start without a token. |
| c2l4-second-agent-docs | RUNS checkpoint, agent BLOCKED | Docs check: API.md lists every route. |
| c2l5-debug-with-logs | RUNS checkpoint, agent BLOCKED | A seeded mistake is introduced for real, found in the request log, caught by a failing test, then fixed. |
| c2l6-backend-checkpoint | RUNS | No agent step. `smoke.sh` and a curl walk-through. |
| c3l1-static-page | RUNS + browser SCRIPTED-NOT-RUN | Page and scripts served and checked over HTTP; board logic tested. Agent step BLOCKED. |
| c3l2-forms-validation | RUNS + browser SCRIPTED-NOT-RUN | Client validation function and the API 400 responses. The form itself is not clicked. Agent step BLOCKED. |
| c3l3-browser-agent | RUNS checkpoint, browser agent BLOCKED + SCRIPTED-NOT-RUN | Seeded front-end bug exists for real; the failing test is real. The browser subagent has no CLI flag, so it is invoked by prompt only. |
| c3l4-fix-found-bug | RUNS checkpoint, agent BLOCKED | Diff of the seeded and the fixed file, tests green. |
| c3l5-a11y-mobile | RUNS checkpoint, browser SCRIPTED-NOT-RUN | Static checks on the HTML and CSS and a computed WCAG contrast ratio. No real keyboard or 390 px browser run. |
| c3l6-e2e-run | RUNS + browser SCRIPTED-NOT-RUN | Node-fetch run of every route and every control's request; HTML controls checked present. No pixel or click run. |
| c4l1-container | RUNS (real Docker) | Image built, container run with a volume, data survived a restart, health check reported healthy. If the base image cannot be pulled the script prints `DOCKER-BLOCKED`. Agent step BLOCKED. |
| c4l2-ci | RUNS checkpoint, agent BLOCKED | Workflow file checked, `make ci` run, a failing test turns it red. The pull-request check on the host is SCRIPTED-NOT-RUN. |
| c4l3-deploy | RUNS against a local stand-in, ssh SCRIPTED-NOT-RUN | `deploy.sh` really ran with a local stand-in for ssh and scp. No real host, no credential. Agent step BLOCKED. |
| c4l4-monitor-rollback | RUNS against a local stand-in, ssh SCRIPTED-NOT-RUN | Probe goes red when the app is stopped and green again; rollback flips the release link. Agent step BLOCKED. |
| c4l5-release-review | RUNS checkpoint, agent BLOCKED | Checklist run on a clean clone: `make ci`, `make smoke`, production-token refusal, token scan, docs check. |
| c4l6-conclusion | RUNS | Scratch repo with tags ch1-done, ch2-done, ch3-done, v1.0.0 built from the milestone directories. |

Totals: 24 lessons, all with a RUNS checkpoint; c1l0, c2l6 and c4l6 have no agent step, the other 21 have an agent step BLOCKED by agy quota. 7 lessons carry a browser step SCRIPTED-NOT-RUN (c1l0, c3l1 to c3l6) and 2 an ssh step SCRIPTED-NOT-RUN (c4l3, c4l4). Antigravity UI segments (editor, browser subagent) are not captured here: the repository state to open is the milestone directory the script prints.

## Receipts (`make gate`, 2026-11-17, exit 0)

- No Python: scanned 180 tracked files, 0 `.py`, 0 calls.
- `bashrs lint --level error` over 46 shell files: 0 errors.
- Offline shell tests: `passed=47 failed=0`.
- Node tests: `node --test` green in all 4 milestones (ch1-done, ch2-done, ch3-done, v1.0.0). Final app: 19 tests, 0 failed; node line coverage 100.00% (branch 98.58%) via `make cover` in milestones/v1.0.0. The coverage run excludes `main.js` (the process entry, exercised by the end-to-end test that spawns it), `test/` and `testlib/`.
- End-to-end: `milestones/v1.0.0/test/e2e.test.js` starts the server on localhost and walks every route and the request behind every control with node fetch; `smoke.sh` does the same with curl. Real DOM behaviour of `public/app.js` (clicks, rendering) is browser-only and NOT RUN.
- Shell coverage (xtrace, `scripts/coverage-trace.sh`): 795 of 840 executable lines, 94.6%, **not 100%**. The gate floor is 94. Missed lines are failure branches (the lint-passes-a-broken-spec guard, the Docker-pull-failure path, node-not-found handling in `lib/common.sh`) and the capture wrapper, which the tests do not run. It is a line trace count, not branch coverage.
- `pv validate contracts/taskpad-title-v1.yaml`: ok (1 contract, the title rule). No ontology files exist to check.
- Key-pattern scan: `scripts/gate-leaks.sh` (grep patterns for key shapes, local paths, internal names), 180 files, 0 findings. The secrets scanner gitleaks is NOT installed on this machine, so it was not run; CI runs it (`make gate-secrets`).
- Not run: htmlhint (not installed; the lint script skips it with a message), any browser, any real SSH host, any pull request.
