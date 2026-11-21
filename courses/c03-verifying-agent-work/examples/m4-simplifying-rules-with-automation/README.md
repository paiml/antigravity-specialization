# Simplifying Rules with Automation

Long prose rules get forgotten under context pressure. This example replaces a multi-paragraph checklist with a minimal Antigravity rule that delegates enforcement to gate.sh. verify.sh proves the gate passes on a clean example and fails on an empty directory, broken syntax, planted TODOs, and incomplete manifests.

## Run

```bash
bash verify.sh
```

Requires bash and standard POSIX utilities (awk, grep, mktemp).

## Why delegate rules to a gate script

1. **Shorter rule, higher compliance**: `.agents/rules/verify-with-gate.md` is six lines instead of a wall of prose.
2. **Deterministic enforcement**: `gate.sh` checks `bash -n`, strict mode (`set -eu`), banned markers (`TODO`/`FIXME`), manifest keys (`title`, `run`), runtime restrictions, and anti-vacuity (`0` scripts = fail).

| file | |
|---|---|
| `.agents/rules/verify-with-gate.md` | minimal rule delegating checks to gate.sh |
| `gate.sh` | deterministic automated gate replacing prose rules |
| `sample-clean/example.toml` | clean sample manifest |
| `sample-clean/run.sh` | clean sample script |
| `verify.sh` | proves clean passes and vacuous, broken, or incomplete targets fail |

---

<sub>Generated — do not edit by hand. Edit `courses/c03-verifying-agent-work/examples/m4-simplifying-rules-with-automation/example.toml` and re-render.</sub>
