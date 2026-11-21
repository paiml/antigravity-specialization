# Which Languages Suit Agentic Coding?

Demonstrates why agents thrive in languages and dialects with fast, strict machine-checkable feedback. First runs an identical agent-generated bug (unset variable typo and failed pipe stage) in permissive bash (exits 0 silently) vs strict bash (fails immediately). Then evaluates a rubric table of language verification properties and refuses malformed or empty inputs.

## Run

```bash
bash verify.sh
```

Requires bash and standard POSIX utilities (awk, grep, mktemp).

## Why strictness matters

1. **Permissive mode** masks an unset-variable typo (`${PREFX}` instead of `${PREFIX}`) and a failing pipe stage (`false | awk ...`), exiting `0` and leaving corrupt artifacts behind.
2. **Strict mode** (`set -euo pipefail`) aborts immediately on the typo and on the broken pipe, giving the agent a clear, deterministic error signal.

| file | |
|---|---|
| `strict-vs-permissive.sh` | runs the same buggy snippet under permissive vs strict mode |
| `languages.tsv` | rubric scoring languages on static types, fail-fast errors, and strict gates |
| `evaluate-languages.sh` | validates and classifies the language rubric table |
| `verify.sh` | verifies strict failure catching, rubric scoring, and bad-input refusal |

---

<sub>Generated — do not edit by hand. Edit `courses/c03-verifying-agent-work/examples/m3-which-languages-suit-agentic-coding/example.toml` and re-render.</sub>
