# Decision log

One entry per choice between real options. Newest last.

## D1: Node built-ins only

Options: a framework with npm packages, or `node:http` and `node:sqlite`. Chosen: built-ins. Why: no install step, nothing to audit or update, and the course machine needs only Node 22. Cost: `node:sqlite` is experimental and prints a warning; routing is hand written.

## D2: SQLite in one file

Options: Postgres, or a file. Chosen: a file at `DB_PATH`. Why: one container, one volume, easy backup. Cost: a single writer, which is fine for a team board.

## D3: One shared bearer token

Options: user accounts, or one token on write endpoints. Chosen: one token, constant-time compare. Why: the spec has no users. Cost: anyone with the token can change anything; rotate it by restarting with a new value.

## D4: Static page, classic scripts

Options: a bundler and a framework, or plain files. Chosen: `board.js` (pure logic, also tested with `require`) and `app.js` (DOM wiring that takes its dependencies as arguments). Why: the page can be tested without a browser and served as-is. Cost: no component model, so the DOM wiring is written by hand.

## D5: Numbered SQL migrations

Options: create tables on start, or numbered files recorded in `schema_migrations`. Chosen: numbered files. Why: a change to a shipped schema is a new file, never an edit. Cost: one more file per change and a table to keep in step with the files.
