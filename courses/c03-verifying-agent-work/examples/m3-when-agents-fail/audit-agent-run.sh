#!/bin/bash
# Post-run auditor for completed agent workspaces.
# Catches empty/placeholder outputs, unguarded pipes, scope drift, and
# contradictory agent logs.

set -euo pipefail

WS="${1:-}"
REL_OUT="${2:-out/report.txt}"
ALLOWED_PREFIX="${3:-work}"

if [ -z "$WS" ] || [ ! -d "$WS" ]; then
    echo "Usage: $0 <workspace-dir> [expected-relpath] [allowed-prefix]" >&2
    exit 1
fi

failed=0

# 1. Expected deliverable must exist, be non-empty, and have no placeholders.
OUT_FILE="$WS/$REL_OUT"
if [ ! -s "$OUT_FILE" ]; then
    echo "FAIL [empty-output]: missing or zero-byte deliverable: $OUT_FILE" >&2
    failed=$((failed + 1))
elif grep -Eq '\b(TODO|FIXME|TBD|PLACEHOLDER)\b' "$OUT_FILE"; then
    echo "FAIL [placeholder-output]: unresolved marker in $OUT_FILE" >&2
    failed=$((failed + 1))
fi

# 2. Shell scripts must parse and enable pipefail when using pipelines.
shopt -s nullglob
scripts=("$WS"/*.sh)
if [ "${#scripts[@]}" -eq 0 ]; then
    echo "FAIL [anti-vacuity]: no .sh scripts in $WS" >&2
    failed=$((failed + 1))
else
    for s in "${scripts[@]}"; do
        if ! bash -n "$s" 2>&1; then
            echo "FAIL [syntax]: bash -n failed on $s" >&2
            failed=$((failed + 1))
        fi
        if grep -v '^[[:space:]]*#' "$s" | grep -Eq '(^|[^|])\|([^|]|$)'; then
            if ! grep -v '^[[:space:]]*#' "$s" | grep -Eq 'set[[:space:]]+.*pipefail'; then
                echo "FAIL [swallowed-pipe]: pipeline without pipefail in $s" >&2
                failed=$((failed + 1))
            fi
        fi
    done
fi

# 3. Scope check via modified-files.txt.
MANIFEST="$WS/modified-files.txt"
if [ ! -s "$MANIFEST" ]; then
    echo "FAIL [missing-manifest]: $MANIFEST is missing or empty" >&2
    failed=$((failed + 1))
else
    bad_paths="$(awk -v pfx="$ALLOWED_PREFIX/" '
        /^[[:space:]]*$/ { next }
        {
            count++
            if (index($0, "..") > 0 || substr($0, 1, 1) == "/" || substr($0, 1, length(pfx)) != pfx) {
                print $0
            }
        }
        END { if (count == 0) print "<empty>" }
    ' "$MANIFEST")"
    if [ -n "$bad_paths" ]; then
        echo "FAIL [scope-drift]: out-of-scope path(s): $bad_paths" >&2
        failed=$((failed + 1))
    fi
fi

# 4. Log consistency check.
LOG="$WS/agent-log.txt"
if [ ! -s "$LOG" ]; then
    echo "FAIL [missing-log]: $LOG is missing or empty" >&2
    failed=$((failed + 1))
else
    has_ok=0
    has_err=0
    if grep -Eiq '(^|[[:space:]])(SUCCESS|PASSED|0 errors)($|[[:space:].])' "$LOG"; then
        has_ok=1
    fi
    if grep -Eiq '(FAIL|ERROR|Total violations:[[:space:]]*[1-9][0-9]*)' "$LOG"; then
        has_err=1
    fi
    if [ "$has_err" -eq 1 ] && [ "$has_ok" -eq 1 ]; then
        echo "FAIL [contradictory-log]: log reports success alongside errors/violations" >&2
        failed=$((failed + 1))
    elif [ "$has_err" -eq 1 ]; then
        echo "FAIL [reported-errors]: log contains errors or violations" >&2
        failed=$((failed + 1))
    fi
fi

if [ "$failed" -ne 0 ]; then
    echo "Audit failed ($failed issue(s))." >&2
    exit 1
fi

echo "Audit passed: $WS"
