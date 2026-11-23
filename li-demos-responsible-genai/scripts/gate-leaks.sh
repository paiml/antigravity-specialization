#!/usr/bin/env bash
# Grep-based leak scan over every tracked file. THIS IS NOT GITLEAKS: it checks a short list of key shapes,
# local absolute paths, user-specific host names and internal ticket-id shapes. CI also runs gitleaks (gate-secrets).
# LEAK_FILES (newline-separated paths) replaces the git file list; the tests use it.
# The pattern words are written in pieces so that this file does not match itself.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
files="${LEAK_FILES-$(git ls-files)}"
n=$(echo "$files" | grep -c . || true)
echo "leaks: scanning $n files (grep patterns, not gitleaks)"
if [ "$n" -eq 0 ]; then
  echo "FAIL scanned 0 files"
  exit 1
fi

key_re='AKIA[0-9A-Z]{16}|(sk|pk)-[A-Za-z0-9]{20,}|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_|xox[bap]-[0-9A-Za-z-]{10,}|-----BEGIN [A-Z ]*PRIVATE KEY|Bearer [A-Za-z0-9._-]{20,}'
# the made-up secrets of the redaction lesson, and the tests that feed redact(), are allowed to look like keys
key_allow='^(c3l4-secrets/data/app\.log|captures/c3l4-secrets\.out|tests/run-tests\.sh)$'

internal_re="/m""nt/|/ho""me/[A-Za-z0-9._-]+|nv""me-raid|for""jar|\\brme""dia|kai""zen|PM""AT-[0-9]+|infr""a#[0-9]+|\\bco""ps?\\b|\\bfle""et\\b|tie""r[- ]?[0-9]|lambda-""labs|gx""10|jet""son|no""ah|Lambda-""Vector|(^|[^A-Za-z0-9_])#[0-9]{3,}"

# the one allowed use of the word: the render theme name a scene spec must carry
theme_ok='^[0-9]+:theme = "rmedia-dark"$'
LEAK_OUT=$(mktemp)
trap 'rm -f "$LEAK_OUT"' EXIT
bad=0
for f in $files; do
  [ -f "$f" ] || continue
  case "$f" in scripts/gate-leaks.sh) continue ;; esac
  if ! echo "$f" | grep -Eq "$key_allow"; then
    if grep -nE -- "$key_re" "$f" >"$LEAK_OUT" 2>/dev/null; then
      sed "s#^#KEY-SHAPE $f:#" "$LEAK_OUT"
      bad=$((bad + 1))
    fi
  fi
  if grep -niE -- "$internal_re" "$f" 2>/dev/null | grep -vE "$theme_ok" >"$LEAK_OUT"; then
    sed "s#^#INTERNAL $f:#" "$LEAK_OUT"
    bad=$((bad + 1))
  fi
done
echo "leaks: $bad file(s) with findings"
if [ "$bad" -ne 0 ]; then
  echo "FAIL"
  exit 1
fi
echo "leaks OK (patterns only; NOT gitleaks)"
