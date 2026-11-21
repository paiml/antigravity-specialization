# Antigravity artifacts for granular control

Antigravity surfaces implementation_plan.md, task.md, and walkthrough.md so humans can gate agent work before edits and audit evidence afterward. check-artifacts.sh verifies that all three artifacts are non-empty, structured, and free of unresolved placeholders.

## Run

```bash
./check-artifacts.sh .
```

## Verify

```bash
./verify.sh
```

Requires bash and standard POSIX/GNU text utilities (grep).

Granular control comes from separating intent (`implementation_plan.md`), progress (`task.md`), and observed proof (`walkthrough.md`). Skipping `## Verification Plan` or leaving `TBD` in `walkthrough.md` fails the contract immediately.

| file | |
|---|---|
| `check-artifacts.sh` | validates plan, task, and walkthrough artifact contracts |
| `implementation_plan.md` | sample plan artifact with review gates and verification plan |
| `task.md` | sample task checklist artifact |
| `walkthrough.md` | sample post-execution walkthrough with observed verification results |
| `verify.sh` | verifies valid artifacts pass and empty or incomplete artifacts fail |

---

<sub>Generated — do not edit by hand. Edit `courses/c03-verifying-agent-work/examples/m2-antigravity-artifacts/example.toml` and re-render.</sub>
