# Components of a job

Breaks down the anatomy of a GitHub Actions job (runs-on, timeout-minutes, env, needs, steps) and runs a multi-job pipeline locally in dependency order so a failure in lint halts downstream test and package jobs.

## Run

```bash
./run-job.sh .github/workflows/pipeline.yml
```

Inspect the job table without executing:

```bash
./inspect-jobs.sh .github/workflows/pipeline.yml
```

## Verify

```bash
./verify.sh
```

Requires bash and standard POSIX tools (awk, mktemp). Runs offline.

A CI job without `timeout-minutes` can hang until GitHub kills it six hours later; a downstream job without `needs:` runs even after `lint` failed. `inspect-jobs.sh` enforces those structural invariants and `run-job.sh` demonstrates fail-fast dependency propagation.

| file | |
|---|---|
| `.github/workflows/pipeline.yml` | multi-job workflow with lint, test, and package jobs |
| `scripts/app.sh` | target script checked by lint and executed by test |
| `inspect-jobs.sh` | validates job fields (runs-on, timeout-minutes, needs graph, steps) |
| `run-job.sh` | executes the workflow jobs in dependency order in a clean temp workspace |
| `verify.sh` | proves valid job graphs pass and missing timeouts or failing steps halt jobs |

---

<sub>Generated — do not edit by hand. Edit `courses/c03-verifying-agent-work/examples/m5-components-of-a-job/example.toml` and re-render.</sub>
