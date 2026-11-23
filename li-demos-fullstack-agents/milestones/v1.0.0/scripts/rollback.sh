#!/usr/bin/env bash
# Rollback: point current back at the previous release, restart, probe.
# Usage: scripts/rollback.sh   (env: DEPLOY_HOST, DEPLOY_DIR, PORT)
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/lib.sh"
prev=$(run "cat '$DEPLOY_DIR/previous' 2>/dev/null || true")
if [ -z "$prev" ]; then
  echo "rollback: no previous release recorded" >&2
  exit 1
fi
echo "rollback: current -> $prev"
run "ln -sfn '$prev' '$DEPLOY_DIR/current'" || exit 1
restart
"$here/probe.sh"
