# Instructions for coding agents

This project is built test-first.

1. Read `spec/slugify.md`. The spec is the source of truth; ask before you change it.
2. Tests live in `tests/cases.txt` (one case per line: `MAX|input|expected`, `-` means no limit). Run them with `make test`.
3. One step at a time: first a failing test, then the smallest change to `src/slugify.sh` that passes, then refactor with the tests green.
4. Never edit a test to make it pass. If a test looks wrong, stop and say why.
5. Shell only (bash). Touch only `src/` and `tests/`.
