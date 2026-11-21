# The Verification Ladder

Demonstrates why weak checks miss real bugs. A 90-degree rotation produces the same 2x3 shape as a matrix transpose, passing Rung 1 (non-empty) and Rung 2 (dimensions) while failing Rung 3 (round-trip involution and top-left invariant). verify.sh runs the ladder on both the true transpose and the wrong rotation.

## Run

```bash
bash verify.sh
```

Requires bash and standard POSIX utilities (awk, diff, mktemp).

## The three rungs in `ladder.sh`

1. **Rung 1 — Existence**: the output file exists and has size > 0.
2. **Rung 2 — Shape**: `rows x cols` swaps from `3x2` to `2x3`. Both `-transpose` and `-rotate 90` pass here.
3. **Rung 3 — Semantic invariant**: applying the transform twice restores the exact input, and the top-left element remains fixed. Only the true transpose passes here.

| file | |
|---|---|
| `fixtures/matrix-3x2.txt` | 3x2 asymmetric input matrix |
| `transpose-matrix.sh` | correct implementation (transpose) |
| `wrong-rotate.sh` | plausible wrong implementation (90-degree rotation, same 2x3 shape) |
| `ladder.sh` | the three-rung verifier (existence, shape, semantic invariant) |
| `verify.sh` | proves the ladder passes transpose and catches rotation and empty output |

---

<sub>Generated — do not edit by hand. Edit `courses/c03-verifying-agent-work/examples/m3-the-verification-ladder/example.toml` and re-render.</sub>
