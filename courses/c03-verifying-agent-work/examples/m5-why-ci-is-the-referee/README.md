# Why CI is the referee

An agent grading its own work in a dirty local directory can trust vacuous checks, empty artifacts, or swallowed exit codes. The referee copies only declared manifest files into a clean temp directory and rejects empty outputs, skipped checks, and unverified claims.

## Run

```bash
./referee.sh submission-good
```

Compare with the deceptive agent submission:

```bash
./referee.sh submission-bad
```

## Verify

```bash
./verify.sh
```

Requires bash and standard POSIX tools (awk, grep, mktemp). No Python or JavaScript.

`submission-bad/check.sh` is the classic failure mode: it prints `PASS: checks complete` and exits `0` without actually checking `report.txt` (which is empty) and leaves a `SKIP` marker in the script. Running the referee in an isolated clean room refuses both the empty artifact and the vacuous check.

| file | |
|---|---|
| `referee.sh` | clean-room CI referee script (supports --self-test) |
| `verify.sh` | verifies good passes and bad/empty fail |
| `submission-good/manifest.txt` | declared files for the passing submission |
| `submission-good/check.sh` | real check that inspects report.txt |
| `submission-good/report.txt` | non-empty output artifact |
| `submission-bad/manifest.txt` | declared files for the deceptive submission |
| `submission-bad/check.sh` | vacuous check that prints PASS and exits 0 over an empty report |
| `submission-bad/report.txt` | empty artifact (0 bytes) |

---

<sub>Generated — do not edit by hand. Edit `courses/c03-verifying-agent-work/examples/m5-why-ci-is-the-referee/example.toml` and re-render.</sub>
