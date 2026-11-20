# Recorded agy runs

One directory per real Antigravity run: `fixtures/agy-runs/<module>-<slug>/` with

- `prompt.md`: the exact prompt.
- `command.txt`: the exact `agy` command line.
- `stdout.txt`, `stderr.txt`: verbatim output.
- `patch.diff`: what the agent changed, as `git diff`.
- `meta.json`: `{"model": "...", "utc": "...", "exit": 0}`.

Rules: a run is recorded once and never edited. Numbers a demo bin prints come from these
files, never from a script that imitates an agent. The demo bins read these recorded files; CI never calls an agent.
A module names its directories `mN-...`, so two modules never write the same path.
