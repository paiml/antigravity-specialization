# Using Test-Driven Development

Demonstrates TDD as an agent verification loop. test_slugify.sh tests a title slugifier across six cases including punctuation, collapsed dashes, and empty-input refusal. verify.sh runs the test suite against slugify_red.sh (must fail, proving the tests are not vacuous) and slugify_green.sh (must pass), plus empty and wrong stubs.

## Run

```bash
bash verify.sh
```

Requires bash and standard POSIX utilities (tr, sed, mktemp).

## The Red-Green contract

1. **RED**: `test_slugify.sh` runs against `slugify_red.sh` and **must fail**. A test suite that passes on a broken stub cannot detect regressions.
2. **GREEN**: `test_slugify.sh` runs against `slugify_green.sh` and **must pass** all 6 cases.

| file | |
|---|---|
| `test_slugify.sh` | six-case TDD specification suite |
| `slugify_red.sh` | initial broken implementation that must fail the suite (RED) |
| `slugify_green.sh` | complete implementation passing all six cases (GREEN) |
| `verify.sh` | proves RED fails, GREEN passes, and empty or wrong stubs fail |

---

<sub>Generated — do not edit by hand. Edit `courses/c03-verifying-agent-work/examples/m4-using-test-driven-development/example.toml` and re-render.</sub>
