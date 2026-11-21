# When Agents Fail

Agents fail in repeatable ways while still reporting success: empty deliverables, swallowed pipeline errors, scope drift outside the target directory, and logs that claim success over non-zero violation counts. audit-agent-run.sh catches all four, and verify.sh proves it passes on a clean run and rejects every failure fixture.

## Run

```bash
bash verify.sh
```

Requires bash and standard POSIX utilities (grep, awk, mktemp).

## Failure modes audited

1. **Empty or placeholder output**: the agent says "Done", but the deliverable is 0 bytes or contains `TODO`/`TBD`.
2. **Swallowed pipeline error**: a script pipes output (`cmd | cat`) without `pipefail`, masking upstream failure.
3. **Scope drift**: `modified-files.txt` touches paths outside the allowed directory prefix or uses `..`.
4. **Contradictory log**: `agent-log.txt` prints `Result: SUCCESS` after `Total violations: 2` or `ERROR`.

| file | |
|---|---|
| `audit-agent-run.sh` | post-run auditor checking output, pipefail, scope, and log consistency |
| `fixtures/good-run/out/report.txt` | valid non-empty deliverable |
| `fixtures/good-run/run.sh` | clean script with pipefail |
| `fixtures/good-run/modified-files.txt` | in-scope file manifest |
| `fixtures/good-run/agent-log.txt` | consistent clean log |
| `verify.sh` | tests good-run plus four distinct agent failure fixtures |

---

<sub>Generated — do not edit by hand. Edit `courses/c03-verifying-agent-work/examples/m3-when-agents-fail/example.toml` and re-render.</sub>
