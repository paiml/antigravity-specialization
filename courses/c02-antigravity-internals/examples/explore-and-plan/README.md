# Explore and plan

Two rungs that write no files. The first asks what this repository is and what enforces its layout; the second asks for a plan. transpose-plan.md is the real artifact the second one produced, and the skill at the repository root is what got built from it.

## Run

```bash
./explore.sh
```

Then `./plan.sh` for the second rung.

Requires the Antigravity CLI (`agy`). Both scripts pass `--mode plan`, so neither writes a file.

`-p` is not a read-only mode; it only means one non-interactive turn. `--mode plan` is the flag that guarantees the working tree is untouched.

Read `transpose-plan.md` next to `.agents/skills/transpose-image/` at the root of this repository: the plan specifies three checks for its verification script, and the script that exists runs exactly those three. It is also where the `-transpose` against `-rotate 90` distinction gets decided, one rung before any file is written.

| file | |
|---|---|
| `explore.sh` | rung 1, asks what the repo does |
| `plan.sh` | rung 2, asks for a plan |
| `transpose-plan.md` | the plan rung 2 produced |

---

<sub>Generated — do not edit by hand. Edit `courses/c02-antigravity-internals/examples/explore-and-plan/example.toml` and re-render.</sub>
