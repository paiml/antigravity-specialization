# Taskpad: Spec

## Goal

A shared task board with three columns: todo, doing, done. One small service, one page, one database file.

## Users and scope

- Users add a task, move it between columns, and delete it.
- No user accounts. Writes need one shared bearer token; reads are open.
- Out of scope: comments, due dates, drag and drop, multiple boards.

## Requirements

1. `GET /healthz` returns `{"status":"ok"}`.
2. `GET /api/tasks` lists tasks; `?status=todo|doing|done` filters. A bad status is 400.
3. `POST /api/tasks` creates a task from `{"title": "..."}`. The title is trimmed and must be 1 to 120 characters, else 400. Returns 201.
4. `PATCH /api/tasks/:id` changes `title` and/or `status`. An unknown id is 404, bad input is 400.
5. `DELETE /api/tasks/:id` removes a task and returns 204. An unknown id is 404.
6. Write endpoints require `Authorization: Bearer $TASKPAD_TOKEN`, compared in constant time. Without it: 401.
7. With `NODE_ENV=production` the server refuses to start without a token.
8. The database path comes from `DB_PATH` (default `data/taskpad.db`). Schema changes are numbered migration files.
9. The page shows the three columns, an add form, and move and delete buttons on every card. The token is typed into a password field and kept in sessionStorage.
10. The page works with the keyboard, at a 390 px wide viewport, and with text contrast of at least 4.5 to 1.

## Acceptance

- `make ci` is green: lint and `node --test`.
- `make smoke` walks the whole API with curl.
- The container starts, answers `/healthz`, and keeps data across a restart through a volume.
- A deploy that fails its health probe is rolled back to the previous release.

## Non-goals

No framework, no build step, no npm dependencies, no ORM.
