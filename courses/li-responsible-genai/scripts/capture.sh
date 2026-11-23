#!/usr/bin/env bash
# capture.sh LESSON [stdin-file]: run a lesson for real and save its output to captures/LESSON.out.
# The captured file is the only source for any "expected output" shown in the course.
# The saved text is sanitized: the home directory becomes ~, the host name is not recorded,
# and internal tracker tags that the apr tool prints are dropped.
set -uo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
lesson="$1"
input="${2:-/dev/null}"
script="${RUN_SCRIPT:-run.sh}"
name="$lesson"
if [ "$script" != "run.sh" ]; then name="$lesson-${script%.sh}"; fi
out="${CAPTURE_DIR:-$here/captures}/$name.out"

# sanitize: stdin -> stdout.
sanitize() {
  sed -E \
    -e "s#$HOME#~#g" \
    -e 's#/home/[A-Za-z0-9._-]+#~#g' \
    -e 's#\[[A-Z]+-[0-9]+\] ##g'
}

{
  echo "# captured $(date -u +%Y-%m-%dT%H:%M:%SZ) with $(apr --version)"
  echo "# model: ${CAPTURE_MODEL:-$(basename "${DEMO_MODEL:-$HOME/.cache/pacha/models/qwen-1.5b-q4k.apr}")}"
  rc=0
  "$here/$lesson/$script" <"$input" 2>&1 || rc=$?
  echo "# exit code: $rc"
} 2>&1 | sanitize >"$out"
tail -n 1 "$out"
echo "$name captured"
exit 0
