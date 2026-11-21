# Agent Rules

- Only bash and standard POSIX tools; no Python or JavaScript.
- Every script under `scripts/` must use `set -euo pipefail`.
- Before reporting any task complete, run `./scripts/check.sh` and confirm it exits `0`.
