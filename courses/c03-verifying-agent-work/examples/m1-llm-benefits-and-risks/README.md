# Benefits and risks of using LLMs

LLMs accelerate scaffolding, yet frequently emit hallucinated file paths, unfinished TODO markers, or '|| true' error masking. audit-draft.sh audits shell drafts against these failure modes before execution.

## Run

```bash
./audit-draft.sh fixtures/good-script.sh
```

To see a risky draft fail the audit:

```bash
./audit-draft.sh fixtures/risky-script.sh
```

## Verify

```bash
./verify.sh
```

Requires bash and standard POSIX/GNU text utilities (grep, sed).

Both `fixtures/good-script.sh` and `fixtures/risky-script.sh` pass `bash -n` syntax checking, proving that syntactic validity alone does not protect against hallucinated paths or swallowed failures.

| file | |
|---|---|
| `audit-draft.sh` | audits generated bash scripts for common LLM risks |
| `fixtures/target.txt` | existing input file referenced by good-script.sh |
| `fixtures/good-script.sh` | compliant script with strict error handling and valid paths |
| `fixtures/risky-script.sh` | plausible LLM draft with a hallucinated path, TODO, and masked failure |
| `verify.sh` | verifies good passes and empty or risky drafts fail |

---

<sub>Generated — do not edit by hand. Edit `courses/c03-verifying-agent-work/examples/m1-llm-benefits-and-risks/example.toml` and re-render.</sub>
