#!/usr/bin/env bash
# capture.sh LESSON: run a lesson for real and save its output to captures/LESSON.out.
# The captured file is the only source for any "expected output" shown in the course.
set -uo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
lesson="$1"
out="${CAPTURE_DIR:-$here/captures}/$lesson.out"
{
  echo "# captured $(date -u +%Y-%m-%dT%H:%M:%SZ) with agy ${AGY_BIN:-agy} $("${AGY_BIN:-agy}" --version 2>&1 | head -n 1)"
} >"$out"
"$here/$lesson/run.sh" </dev/null 2>&1 | sed "s|$here|<repo>|g" >>"$out"
rc=${PIPESTATUS[0]}
echo "# exit code: $rc" >>"$out"
echo "$lesson exit=$rc"
exit 0
