#!/bin/bash
# Deterministic guardrail gate for LLM-generated deliverables.
# Refuses empty outputs, path traversal, disallowed runtimes, secret literals,
# and syntax errors.

set -euo pipefail

TARGET_DIR="${1:-}"
if [ -z "$TARGET_DIR" ] || [ ! -d "$TARGET_DIR" ]; then
    echo "Usage: $0 <target-dir>" >&2
    exit 1
fi

shopt -s nullglob

disallowed=("$TARGET_DIR"/*.py "$TARGET_DIR"/*.js)
if [ "${#disallowed[@]}" -gt 0 ]; then
    echo "FAIL: disallowed runtime file(s) found: ${disallowed[*]}" >&2
    exit 1
fi

scripts=("$TARGET_DIR"/*.sh)
if [ "${#scripts[@]}" -eq 0 ]; then
    echo "FAIL: anti-vacuity check — no .sh deliverables found in $TARGET_DIR" >&2
    exit 1
fi

failed=0
for f in "${scripts[@]}"; do
    if [ ! -s "$f" ]; then
        echo "FAIL: empty file: $f" >&2
        failed=$((failed + 1))
        continue
    fi
    if ! bash -n "$f" 2>&1; then
        echo "FAIL: bash syntax error in $f" >&2
        failed=$((failed + 1))
    fi
    if grep -En '(\.\./|/etc/|/var/|/root/)' "$f" >/dev/null; then
        echo "FAIL: path traversal or restricted system path in $f" >&2
        failed=$((failed + 1))
    fi
    if grep -En '^[[:space:]]*(API_KEY|SECRET_KEY|TOKEN|PASSWORD)=["'"'"'][A-Za-z0-9_-]{4,}' "$f" >/dev/null; then
        echo "FAIL: hardcoded credential literal in $f" >&2
        failed=$((failed + 1))
    fi
done

if [ "$failed" -ne 0 ]; then
    echo "Guardrail gate failed ($failed violation(s))." >&2
    exit 1
fi

echo "Guardrail gate passed (${#scripts[@]} script(s) verified)."
