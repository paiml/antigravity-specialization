# Mitigating Risks of LLMs

Pairs an Antigravity rule file with a deterministic bash guardrail gate that blocks empty deliverables, path traversal, disallowed runtimes, and leaked credential literals. verify.sh proves the gate passes on clean output and fails on each planted risk.

## Run

```bash
bash verify.sh
```

Requires bash and standard POSIX utilities (grep, awk, mktemp).

## What it checks

1. **Anti-vacuity**: at least one `.sh` file must exist in the target directory.
2. **Non-empty output**: zero-byte deliverables fail immediately.
3. **Path boundary**: references to `../`, `/etc/`, `/var/`, or `/root/` are rejected.
4. **Runtime constraint**: `.py` and `.js` files are blocked in a bash-only project.
5. **Secret hygiene**: hardcoded `API_KEY`, `SECRET_KEY`, `TOKEN`, or `PASSWORD` literals fail.
6. **Syntax**: every `.sh` file must pass `bash -n`.

| file | |
|---|---|
| `.agents/rules/guardrails.md` | workspace rule binding the agent to the guardrail gate |
| `guardrail-check.sh` | deterministic guardrail verifier |
| `sample-agent-output/transform.sh` | clean sample deliverable |
| `verify.sh` | proves clean passes and every planted risk fails |

---

<sub>Generated — do not edit by hand. Edit `courses/c03-verifying-agent-work/examples/m3-mitigating-risks-of-llms/example.toml` and re-render.</sub>
