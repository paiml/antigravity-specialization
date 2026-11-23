# Architecture

```
browser  --HTTP-->  server.js  --calls-->  db.js  --node:sqlite-->  data/taskpad.db
   ^                    |
   +---- public/ -------+  (static files)
```

## Files

| File | Job |
|---|---|
| `main.js` | Reads the environment, opens the database, starts the server. |
| `server.js` | Routes, validation, the bearer check, static files, one log line per request. `createServer` takes its database, token and log function as arguments. |
| `db.js` | Opens the database, applies `migrations/*.sql` in order, exposes list, get, create, update, remove. |
| `migrations/` | Numbered SQL files. `schema_migrations` records which ones ran. |
| `public/board.js` | Pure board logic: title check, grouping by status, neighbour column. |
| `public/app.js` | Wires the page to the API. Takes `document`, `fetch`, `storage` as arguments. |
| `public/index.html`, `style.css` | The page. |
| `test/` | `node --test` tests. `testlib/` holds the server harness and a small fake DOM. |
| `scripts/` | `lint.sh`, `smoke.sh`, and the deploy, probe and rollback scripts. |

## Request flow

1. `server.js` parses the URL. `/healthz` answers directly. `/api/*` goes to the API handler. Anything else is a static file from `public/`.
2. Write methods check the bearer token first, then the id, then the body.
3. Errors are JSON `{"error": "..."}`. An unexpected error is a 500 with no detail in the body; the detail is in the log.

## Failure modes

- A bad token or missing header: 401, nothing changes.
- A body larger than 64 KB: 413.
- A migration that throws: the transaction is rolled back by SQLite when the process exits, and the server does not start.
- A missing database directory: created on start.
