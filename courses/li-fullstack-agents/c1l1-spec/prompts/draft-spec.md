Write SPEC.md for a small app called Taskpad: a shared task board with three columns (todo, doing, done).

Use these sections in this order: Goal, Users and scope, Requirements, Acceptance, Non-goals.
Number the requirements. Each one states one behaviour a test can check, with the exact status codes.
Cover: a health endpoint, listing and filtering tasks, creating a task (title trimmed, 1 to 120 characters),
changing and deleting a task, a shared bearer token for writes, a production start check, the database path,
and the page (columns, add form, move and delete buttons, keyboard, 390 px width, contrast).
Acceptance must name `make ci` and a smoke test. Non-goals: no framework, no build step, no npm dependencies.
Do not write any code yet.
