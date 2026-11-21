# Using CI for verifying agent work

Verifying an agent's pull request requires more than running unit tests: CI must prove the agent stayed inside allowed paths, left no TODOs or secrets, did not delete or comment out assertions, and passes all tests in a clean workspace.

## Run

```bash
./verify-agent-pr.sh sample-pr
```

## Verify

```bash
./verify.sh
```

Requires bash and standard POSIX tools (awk, grep, mktemp). Runs offline.

`verify.sh` clones `sample-pr` into a temp directory and tests four ways an agent pull request goes wrong: an empty PR, an out-of-scope edit to `.github/workflows/ci.yml`, a planted `TODO` or API key pattern, and a weakened test suite whose assertions were commented out.

| file | |
|---|---|
| `.github/workflows/verify-agent-pr.yml` | GitHub Actions workflow invoking verify-agent-pr.sh |
| `verify-agent-pr.sh` | agent-PR CI gate (scope, hygiene, test integrity, clean-room test run) |
| `sample-pr/allowed-paths.txt` | allowed path prefixes the agent is permitted to edit |
| `sample-pr/changed-files.txt` | files touched in the agent pull request |
| `sample-pr/src/transform.sh` | agent-written implementation script |
| `sample-pr/tests/run_tests.sh` | unit test suite verifying transform.sh |
| `verify.sh` | proves sample-pr passes and 4 planted agent failure modes fail |

---

<sub>Generated — do not edit by hand. Edit `courses/c03-verifying-agent-work/examples/m5-ci-verifying-agent-work/example.toml` and re-render.</sub>
