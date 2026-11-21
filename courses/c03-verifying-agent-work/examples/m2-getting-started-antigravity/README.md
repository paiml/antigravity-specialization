# Getting started with Antigravity

Demonstrates the safe starting posture with the Antigravity CLI: running a single non-interactive prompt (`agy -p`) paired with `--mode plan` so the agent inspects files and reports contracts without modifying the working tree.

## Run

```bash
./explore-workspace.sh
```

## Verify

```bash
./verify.sh
```

Live: needs agy. Requires the Antigravity CLI (`agy`) for live execution. `verify.sh` checks the script contract and session expectations offline without invoking `agy`.

`-p` alone only selects single-turn non-interactive output; `--mode plan` is the flag that enforces read-only exploration before you grant write permissions.

| file | |
|---|---|
| `explore-workspace.sh` | runs agy -p with --mode plan for read-only inspection |
| `expected-session.txt` | reference record of expected read-only session invariants |
| `verify.sh` | validates the launch script and session record without calling agy |

---

<sub>Generated — do not edit by hand. Edit `courses/c03-verifying-agent-work/examples/m2-getting-started-antigravity/example.toml` and re-render.</sub>
