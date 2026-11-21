---
trigger: always_on
description: Enforce project quality by running gate.sh instead of manual checklists.
---

# Automated Verification Rule

Before finishing any change in an example directory, run `bash gate.sh <dir>`.
Do not report success if `gate.sh` exits non-zero; fix every reported failure and re-run.
