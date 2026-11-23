# Build a Full-Stack App with Google Antigravity Agents: demo code

Companion code for the course *Build a Full-Stack App with Google Antigravity Agents* by Pragmatic AI Labs. You build **Taskpad**, a shared task board with three columns (todo, doing, done), by working with coding agents in four chapters. This repository holds Taskpad at the end of every chapter, one demo script per lesson, and the prompt files the lessons give to the agent.

Taskpad needs only Node and shell: Node 22 or newer, no npm packages, no Python, no Rust. The server uses `node:http` and `node:sqlite` (Node prints an ExperimentalWarning for `node:sqlite`; that is expected). The front end is static files.

## Where Taskpad is, chapter by chapter

| Directory | State | Chapter milestone |
|---|---|---|
| `milestones/ch1-done` | Spec, context file, decision log, scaffold, `/healthz`, `make ci` | 1 From Idea to a Running Stack |
| `milestones/ch2-done` | Migrations, tested CRUD API, bearer token, API docs, `smoke.sh` | 2 The Backend with Agents |
| `milestones/ch3-done` | Page, forms with validation, board logic, end-to-end test | 3 The Front End and Browser Checks |
| `milestones/v1.0.0` | Dockerfile, CI workflow, deploy, probe and rollback scripts, release checklist | 4 Ship It |

Each milestone is a complete project. `cd milestones/ch2-done && node --test` runs its tests; `make ci` runs lint and tests; `make smoke` walks the whole API with curl on a free port; `node main.js` serves it (set `TASKPAD_TOKEN`; `PORT` and `DB_PATH` are optional).

## API (port 3000 by default)

`GET /healthz`, `GET /api/tasks?status=`, `POST /api/tasks`, `PATCH /api/tasks/:id`, `DELETE /api/tasks/:id`. A title is trimmed and must be 1 to 120 characters. Write endpoints need `Authorization: Bearer $TASKPAD_TOKEN`; reads are open. A bad status or title is 400, an unknown id is 404. See `milestones/v1.0.0/docs/API.md`.

## Lessons

Each lesson has a directory with a `run.sh` and, where an agent is involved, a `prompts/` directory with the exact text given to the agent.

| Chapter | Lessons |
|---|---|
| 1 | `c1l0-what-we-build`, `c1l1-spec`, `c1l2-context`, `c1l3-architecture-review`, `c1l4-stack-check`, `c1l5-scaffold-commit` |
| 2 | `c2l1-migrations`, `c2l2-api-tdd`, `c2l3-auth`, `c2l4-second-agent-docs`, `c2l5-debug-with-logs`, `c2l6-backend-checkpoint` |
| 3 | `c3l1-static-page`, `c3l2-forms-validation`, `c3l3-browser-agent`, `c3l4-fix-found-bug`, `c3l5-a11y-mobile`, `c3l6-e2e-run` |
| 4 | `c4l1-container`, `c4l2-ci`, `c4l3-deploy`, `c4l4-monitor-rollback`, `c4l5-release-review`, `c4l6-conclusion` |

```bash
c2l2-api-tdd/run.sh          # tests red against the stub server, then green
HOLD=1 c3l1-static-page/run.sh   # keeps the app up so you can open the printed address in a browser
```

Every script copies a milestone into a scratch directory, starts Taskpad on a free local port, and removes everything when it exits. Nothing is written into this repository. Lessons with an agent step call the `agy` CLI (`agy --print=PROMPT`); if `agy` is missing or has no quota the step prints an `AGY-BLOCKED` line and the script carries on with the steps that need no agent. No script logs in anywhere or asks for credentials.

`captures/` holds the real output of each script from one recorded run. `DEMO-STATUS.md` says what ran, what is scripted but was not run, and what was blocked.

Steps that happen in a browser (opening the page, the browser agent, keyboard and mobile checks) are described in the lesson script as `BROWSER STEP` lines; the repository state they need is what the script starts.

## Checks

```bash
make gate    # no Python, bashrs lint, offline tests, node tests and coverage, leak patterns, shell coverage, contract
```

`make gate` needs Node 22 or newer, `bash`, `curl`, `sqlite3`, `shellcheck`, `git` and `bashrs`. The container lesson also uses Docker when a daemon is present. `make gate-secrets` runs gitleaks if you have it installed; the grep-based `gate-leaks` is not a substitute for it.

## Intended use and licence

Teaching code. The bearer tokens in the scripts (`dev-token`, `test-token`, `demo-token`) are throwaway values for localhost; use your own secret for anything real. MIT licence, see `LICENSE`.
