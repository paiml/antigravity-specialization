# What is generative AI?

Generative models predict probable next tokens rather than compiling deterministic rules, so plausible outputs can drift in keys, line counts, or checksum formats. check-samples.sh enforces a strict contract on candidate artifacts and rejects stochastic drift.

## Run

```bash
./check-samples.sh
```

To check a single artifact file directly (exits non-zero on failure):

```bash
./check-samples.sh samples/candidate-valid.txt
```

## Verify

```bash
./verify.sh
```

Requires bash and standard POSIX/GNU text utilities (awk, grep, wc).

`samples/candidate-drifted.txt` looks reasonable to a human glancing at it, yet it adds conversational prose, truncates the digest to 8 hex characters, and renames `STATUS` to `STATE`. Deterministic checks catch all of these without trusting model confidence.

| file | |
|---|---|
| `check-samples.sh` | deterministic invariant checker for candidate artifacts |
| `samples/candidate-valid.txt` | compliant structured artifact |
| `samples/candidate-drifted.txt` | plausible-looking stochastic drift that fails invariants |
| `verify.sh` | proves valid passes and empty or drifted artifacts fail |

---

<sub>Generated — do not edit by hand. Edit `courses/c03-verifying-agent-work/examples/m1-what-is-generative-ai/example.toml` and re-render.</sub>
