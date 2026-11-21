# Introduction to GitHub Actions

A GitHub Actions workflow declares when CI runs (on), what permissions it holds (least privilege), and what jobs execute. check-workflow.sh validates the workflow structure, pinned action versions, and referenced scripts locally without needing GitHub.

## Run

```bash
./check-workflow.sh .github/workflows/verify.yml
```

## Verify

```bash
./verify.sh
```

Requires bash and standard POSIX tools (awk, grep, mktemp). Runs offline.

Catching a broken workflow locally saves a commit-and-wait loop on GitHub. `check-workflow.sh` refuses tabs in YAML, missing `on:`/`permissions:`/`jobs:` keys, unpinned `@main` action references, and `run:` commands pointing at scripts that do not exist.

| file | |
|---|---|
| `.github/workflows/verify.yml` | minimal GitHub Actions workflow with pinned actions and read-only permissions |
| `scripts/smoke.sh` | deterministic smoke check invoked by the workflow |
| `check-workflow.sh` | offline bash+awk validator for workflow structure and pinned actions |
| `verify.sh` | verifies the workflow passes and malformed/empty workflows fail |

---

<sub>Generated — do not edit by hand. Edit `courses/c03-verifying-agent-work/examples/m5-github-actions-intro/example.toml` and re-render.</sub>
