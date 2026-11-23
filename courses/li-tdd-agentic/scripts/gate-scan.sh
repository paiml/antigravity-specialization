#!/usr/bin/env bash
# Public-repo scan: key-shaped strings (gitleaks stand-in) and words that must not appear in a public repo.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
n=$(git ls-files | wc -l | tr -d ' ')
keys='(s[k]-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|gh[p]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|AIza[0-9A-Za-z_-]{30,}|xox[baprs]-[A-Za-z0-9-]{10,}|-----BEGIN [A-Z ]*PRIVATE KEY-----)'
words='(kaizen|fleet|forjar|/mnt/nvme|/home/[a-z]+|lambda-labs|ticket|cop-inbox|operator|quorum)'
k=$(git grep -nIE "$keys" -- . ':!scripts/gate-scan.sh' | wc -l | tr -d ' ')
w=$(git grep -nIiE "$words" -- . ':!scripts/gate-scan.sh' | wc -l | tr -d ' ')
echo "scan: $n tracked files, $k key-shaped strings, $w internal words"
if [ "$n" -eq 0 ]; then echo "FAIL scanned 0 files"; exit 1; fi
if [ "$k" -ne 0 ] || [ "$w" -ne 0 ]; then
  git grep -nIiE "$keys|$words" -- . ':!scripts/gate-scan.sh' | head -n 10
  echo "FAIL"
  exit 1
fi
echo "scan OK"
