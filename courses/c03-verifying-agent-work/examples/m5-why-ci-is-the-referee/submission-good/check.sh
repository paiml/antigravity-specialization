#!/bin/bash
set -euo pipefail

[ -s report.txt ] || { echo "FAIL: report.txt is missing or empty" >&2; exit 1; }
grep -q '^status=verified$' report.txt || { echo "FAIL: status=verified not found" >&2; exit 1; }
grep -q '^errors=0$' report.txt || { echo "FAIL: errors=0 not found" >&2; exit 1; }

echo "PASS: report.txt is non-empty and verified with 0 errors"
