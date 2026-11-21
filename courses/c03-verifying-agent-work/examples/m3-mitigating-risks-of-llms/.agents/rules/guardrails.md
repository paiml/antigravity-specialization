---
trigger: always_on
description: Hard guardrails for LLM-generated scripts in this workspace.
---

# Workspace Guardrails

1. Write deliverables only inside the requested output directory; never use `../` or system paths (`/etc/`, `/var/`, `/root/`).
2. Use bash and standard Unix tools only; never introduce `.py` or `.js` files.
3. Never hardcode credential literals (`API_KEY`, `SECRET_KEY`, `TOKEN`, `PASSWORD`).
4. Run `bash guardrail-check.sh <output-dir>` before reporting completion; if it exits non-zero, fix the violation rather than summarizing around it.
