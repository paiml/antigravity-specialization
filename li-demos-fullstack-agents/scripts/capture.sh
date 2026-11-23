#!/usr/bin/env bash
# capture.sh LESSON: run a lesson for real and save its output to captures/LESSON.out.
# The captured file is the only source for any "expected output" shown in the course.
# The saved text is sanitized: the home directory becomes ~ and the host name is not recorded.
# A quota or auth failure from agy is remembered in .run/agy-state, so one capture session asks agy once.
set -uo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
lesson="$1"
out="${CAPTURE_DIR:-$here/captures}/$lesson.out"
mkdir -p "$here/.run"
AGY_STATE="${AGY_STATE:-$here/.run/agy-state}"
export AGY_STATE

# sanitize: stdin -> stdout.
sanitize() {
  sed -E \
    -e "s#$HOME#~#g" \
    -e 's#/home/[A-Za-z0-9._-]+#~#g'
}

{
  echo "# captured $(date -u +%Y-%m-%dT%H:%M:%SZ) with node $(node --version 2>/dev/null || echo none), agy $(${AGY_BIN:-agy} --version 2>&1 | head -n 1)"
  rc=0
  "$here/$lesson/run.sh" </dev/null 2>&1 || rc=$?
  echo "# exit code: $rc"
} 2>&1 | sanitize >"$out"
tail -n 1 "$out"
echo "$lesson captured"
exit 0
