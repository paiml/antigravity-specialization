# Project context for coding agents

Read this before you change anything. It is the file Antigravity loads as project context.

## What this is

Taskpad, a three-column task board. Read `SPEC.md` for what it must do and `docs/ARCHITECTURE.md` for how it is built.

## Rules

- Node 22 only. No npm dependencies: use `node:http`, `node:sqlite`, `node:test`, `node:crypto`.
- No Python, no build step, no framework.
- Tests first: write a failing `node --test` test, then the code that makes it pass.
- Run `make ci` before you say a change is done. Paste the result, not a summary of it.
- Never print, log or commit a token. Tokens come from the `TASKPAD_TOKEN` environment variable.
- Do not edit a migration that has shipped. Add a new numbered file in `migrations/`.
- Keep the page script free of `innerHTML`: build nodes and set `textContent`.
- Ask before you add a file outside the layout in `docs/ARCHITECTURE.md`.

## Commands

- `make test`: run the tests.
- `make lint`: shellcheck and htmlhint.
- `make run`: start on port 3000 (uses a development token and says so).
- `make smoke`: walk the API with curl on a scratch port.
- `make ci`: lint and test.

## Definition of done

The spec line is met, a test covers it, `make ci` is green, and `DECISIONS.md` has a line if you chose between options.
