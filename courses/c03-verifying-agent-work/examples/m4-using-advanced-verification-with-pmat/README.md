# Using Advanced Verification with PMAT

Automates pmat quality-gate (complexity, satd, dead-code) inside pmat-gate.sh so non-blocking findings and empty scopes cannot masquerade as passes. verify.sh proves a clean Rust fixture passes, a planted TODO leaves raw pmat exiting 0 while pmat-gate.sh fails, and an empty directory is rejected.

## Run

```bash
bash verify.sh
```

Requires `pmat` on PATH and standard POSIX utilities (sed, grep, find, mktemp).

## Why `pmat-gate.sh` reads totals instead of `$?`

`pmat quality-gate` exits `0` when findings are non-blocking (for example, a planted `TODO` produces `Total violations: 1`, `Blocking violations: 0`, `Quality Gate: PASSED`). `pmat-gate.sh` captures the full output first (`OUT=...; EC=$?`), refuses zero-file scopes, and fails if `Total violations` is missing or above `0`.

| file | |
|---|---|
| `pmat-gate.sh` | strict wrapper parsing Total violations and scope rather than trusting exit code |
| `fixture/Cargo.toml` | self-contained Rust crate manifest for pmat analysis |
| `fixture/src/lib.rs` | clean Rust source fixture |
| `verify.sh` | proves clean passes, planted TODO fails strict gate, and empty fails |

---

<sub>Generated — do not edit by hand. Edit `courses/c03-verifying-agent-work/examples/m4-using-advanced-verification-with-pmat/example.toml` and re-render.</sub>
