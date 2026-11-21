# Anatomy of a verified repository

Inspects every structural invariant of a verified repository: project.toml declares artifacts without dangling links, AGENTS.md and CI agree on the exact verification command, every script enforces strict mode, and the verification script passes in a clean room.

## Run

```bash
./audit-repo.sh sample-verified-repo
```

## Verify

```bash
./verify.sh
```

Requires bash and standard POSIX tools (awk, grep, mktemp). Runs offline.

A verified repository connects four layers with zero drift: the declarative manifest (`project.toml`), the agent contract (`AGENTS.md`), the local verifier (`scripts/check.sh`), and the CI referee (`.github/workflows/ci.yml`). `verify.sh` proves the audit catches an empty repo, a dangling manifest reference, and an `AGENTS.md`/CI command mismatch.

| file | |
|---|---|
| `audit-repo.sh` | structural auditor checking manifest, AGENTS.md/CI alignment, and strict mode |
| `verify.sh` | proves sample-verified-repo passes and broken/empty repos fail |
| `sample-verified-repo/project.toml` | declarative manifest listing build, verify, and tracked artifacts |
| `sample-verified-repo/AGENTS.md` | agent instructions referencing the exact verification command |
| `sample-verified-repo/.github/workflows/ci.yml` | CI workflow running the same verification command |
| `sample-verified-repo/scripts/build.sh` | deterministic build script |
| `sample-verified-repo/scripts/check.sh` | verification script with positive and negative checks |
| `sample-verified-repo/data/input.txt` | sample input fixture |

---

<sub>Generated — do not edit by hand. Edit `courses/c03-verifying-agent-work/examples/m6-anatomy-of-a-verified-repo/example.toml` and re-render.</sub>
