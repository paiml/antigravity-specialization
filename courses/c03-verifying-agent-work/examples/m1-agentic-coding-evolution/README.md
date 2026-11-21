# How agentic coding has evolved

Demonstrates the shift from single-shot generation and exit-code-only checks to an explicit verification contract. Validates a service config against strict structural and value invariants, rejecting empty or malformed inputs.

## Run

```bash
./evolve.sh
```

## Verify

```bash
./verify.sh
```

Requires bash and standard POSIX/GNU text utilities (awk, grep).

Early coding assistants generated text with no execution loop at all. Adding tool execution helped, but checking only `$?` still passes when an output file is empty or holds invalid values. Contract-verified agentic steps check concrete postconditions on the resulting artifact and fail loudly when invariants break.

| file | |
|---|---|
| `evolve.sh` | compares naive checks against contract-verified extraction |
| `sample-config.env` | valid service configuration fixture |
| `verify.sh` | verifies valid output and rejects empty or corrupted configs |

---

<sub>Generated — do not edit by hand. Edit `courses/c03-verifying-agent-work/examples/m1-agentic-coding-evolution/example.toml` and re-render.</sub>
