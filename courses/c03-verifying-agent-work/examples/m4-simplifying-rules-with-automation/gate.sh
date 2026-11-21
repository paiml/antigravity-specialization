#!/bin/bash
# Single automated gate replacing multi-paragraph prose checklists.

set -euo pipefail

DIR="${1:-}"
if [ -z "$DIR" ] || [ ! -d "$DIR" ]; then
    echo "Usage: $0 <example-dir>" >&2
    exit 1
fi

shopt -s nullglob

bad_rt=("$DIR"/*.py "$DIR"/*.js)
if [ "${#bad_rt[@]}" -gt 0 ]; then
    echo "FAIL: disallowed runtime file(s): ${bad_rt[*]}" >&2
    exit 1
fi

scripts=("$DIR"/*.sh)
if [ "${#scripts[@]}" -eq 0 ]; then
    echo "FAIL: anti-vacuity — no .sh scripts found in $DIR" >&2
    exit 1
fi

failed=0
for s in "${scripts[@]}"; do
    if [ ! -s "$s" ]; then
        echo "FAIL: empty script: $s" >&2
        failed=$((failed + 1))
        continue
    fi
    if ! bash -n "$s" 2>&1; then
        echo "FAIL: syntax error in $s" >&2
        failed=$((failed + 1))
    fi
    if ! grep -Eq '^[[:space:]]*set[[:space:]]+-eu' "$s"; then
        echo "FAIL: missing strict mode (set -eu...) in $s" >&2
        failed=$((failed + 1))
    fi
    if grep -En '\b(TODO|FIXME)\b' "$s" >/dev/null; then
        echo "FAIL: unresolved TODO/FIXME marker in $s" >&2
        failed=$((failed + 1))
    fi
done

TOML="$DIR/example.toml"
if [ ! -s "$TOML" ]; then
    echo "FAIL: missing or empty $TOML" >&2
    failed=$((failed + 1))
else
    for key in title run; do
        if ! awk -v k="$key" '
            /^\[example\]$/ { in_ex = 1; next }
            /^\[/ { in_ex = 0; next }
            in_ex && $0 ~ "^[[:space:]]*" k "[[:space:]]*=" {
                p = index($0, "=")
                v = substr($0, p + 1)
                sub(/^[[:space:]]+/, "", v)
                sub(/[[:space:]]+$/, "", v)
                if (length(v) >= 3 && substr(v, 1, 1) == "\"" && substr(v, length(v), 1) == "\"") {
                    found = 1; exit 0
                }
            }
            END { if (!found) exit 1 }
        ' "$TOML"; then
            echo "FAIL: missing or empty [example].$key in $TOML" >&2
            failed=$((failed + 1))
        fi
    done
fi

if [ "$failed" -ne 0 ]; then
    echo "Gate failed ($failed violation(s))." >&2
    exit 1
fi

echo "Gate passed: $DIR (${#scripts[@]} script(s) checked)."
