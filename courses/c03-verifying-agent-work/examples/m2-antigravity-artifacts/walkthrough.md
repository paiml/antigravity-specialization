# Walkthrough

Implemented the artifact checker and validated all negative failure modes in a temporary directory.

## Verification Results

- Checked `implementation_plan.md`, `task.md`, and `walkthrough.md` via `./check-artifacts.sh .`: passed (`exit 0`).
- Verified empty plan, missing verification plan, empty checklist, and a walkthrough left with a placeholder word all exit `1`.
