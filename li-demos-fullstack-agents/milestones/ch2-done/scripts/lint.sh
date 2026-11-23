#!/usr/bin/env bash
# Lint: shellcheck over scripts/, htmlhint over public/ when installed. Prints how many files it saw.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
sh_files=$(find scripts -name '*.sh' | sort)
n=$(echo "$sh_files" | grep -c . || true)
echo "lint: $n shell files"
if [ "$n" -eq 0 ]; then
  echo "FAIL scanned 0 files"
  exit 1
fi
if command -v shellcheck >/dev/null 2>&1; then
  # shellcheck disable=SC2086
  shellcheck -x -P SCRIPTDIR $sh_files || exit 1
else
  echo "shellcheck not installed: shell files NOT checked"
fi
if [ -d public ]; then
  if command -v htmlhint >/dev/null 2>&1; then
    htmlhint public/index.html || exit 1
  else
    echo "htmlhint not installed: html NOT checked"
  fi
fi
echo "lint OK"
