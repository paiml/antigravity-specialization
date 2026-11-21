# Antigravity analysis on an agentic repo

Uses the Antigravity CLI in read-only --mode plan to audit an agentic repository with planted verification gaps. Because live agy steps are non-deterministic, verify.sh validates the offline citation-and-ground-truth checker instead of calling agy.

## Run (live)

```bash
./analyze.sh
```

Live: needs agy. Requires the Antigravity CLI (`agy`) for ./analyze.sh. ./verify.sh runs offline using bash and standard POSIX tools only.

## Verify (offline)

```bash
./verify.sh
```

Requires bash and standard POSIX tools (`awk`, `grep`, `wc`, `mktemp`). Does **not** call `agy`.

An LLM analysis is only trustworthy if every `file:line` it cites exists and falls within the file's real line count. `check-analysis.sh` verifies `sample-analysis.md` against `target-repo/`, and `verify.sh` proves the checker rejects empty reports, hallucinated files, out-of-range line numbers, and missed defects.

| file | |
|---|---|
| `analyze.sh` | live read-only agy -p ... --mode plan analysis command |
| `check-analysis.sh` | offline checker verifying cited file:line paths and required findings |
| `sample-analysis.md` | reference analysis report citing exact file:line locations in target-repo/ |
| `target-repo/AGENTS.md` | fixture agent guide lacking a concrete verification command |
| `target-repo/.github/workflows/ci.yml` | fixture workflow with unpinned @main action and masked exit codes |
| `target-repo/scripts/process.sh` | fixture script missing strict mode and input validation |
| `target-repo/tests/test_process.sh` | fixture vacuous test that ignores failures and exits 0 |
| `verify.sh` | offline verification of analyze.sh flags and hallucination rejection |

---

<sub>Generated — do not edit by hand. Edit `courses/c03-verifying-agent-work/examples/m6-antigravity-analysis/example.toml` and re-render.</sub>
