# Decision log

One entry per choice between real options. Newest last.

## D1: Node built-ins only

Options: a framework with npm packages, or `node:http` and `node:sqlite`. Chosen: built-ins. Why: no install step, nothing to audit or update, and the course machine needs only Node 22. Cost: `node:sqlite` is experimental and prints a warning; routing is hand written.

