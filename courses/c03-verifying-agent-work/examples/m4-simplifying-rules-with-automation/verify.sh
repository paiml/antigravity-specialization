#!/bin/bash
# Verifies rule linkage, clean pass, and four automated gate failure cases.

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

GATE="$HERE/gate.sh"
RULE="$HERE/.agents/rules/verify-with-gate.md"
SAMPLE="$HERE/sample-clean"

[ -s "$RULE" ] || { echo "FAIL: missing rule $RULE" >&2; exit 1; }
grep -q 'gate.sh' "$RULE" || { echo "FAIL: rule must reference gate.sh" >&2; exit 1; }

# 1. Clean sample passes.
bash "$GATE" "$SAMPLE" >/dev/null
echo "  PASS  clean sample passes gate"

# 2. Empty directory fails anti-vacuity check.
mkdir -p "$WORK/empty"
if bash "$GATE" "$WORK/empty" >/dev/null 2>&1; then
    echo "  FAIL  gate passed on empty directory" >&2
    exit 1
fi
echo "  PASS  empty directory rejected"

# 3. Broken bash syntax fails.
cp -r "$SAMPLE" "$WORK/bad-syntax"
printf 'if [ 1 -eq 1 ; then\n' >> "$WORK/bad-syntax/run.sh"
if bash "$GATE" "$WORK/bad-syntax" >/dev/null 2>&1; then
    echo "  FAIL  gate passed on syntax error" >&2
    exit 1
fi
echo "  PASS  syntax error rejected"

# 4. Planted TODO fails.
cp -r "$SAMPLE" "$WORK/bad-todo"
printf '# TODO: finish this later\n' >> "$WORK/bad-todo/run.sh"
if bash "$GATE" "$WORK/bad-todo" >/dev/null 2>&1; then
    echo "  FAIL  gate passed with TODO marker" >&2
    exit 1
fi
echo "  PASS  TODO marker rejected"

# 5. Missing run key in example.toml fails.
cp -r "$SAMPLE" "$WORK/bad-toml"
printf '[example]\ntitle = "Missing Run"\n' > "$WORK/bad-toml/example.toml"
if bash "$GATE" "$WORK/bad-toml" >/dev/null 2>&1; then
    echo "  FAIL  gate passed on incomplete example.toml" >&2
    exit 1
fi
echo "  PASS  incomplete example.toml rejected"

echo "contract: m4-simplifying-rules-with-automation OK"
