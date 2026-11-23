#!/usr/bin/env bash
# Deploy a version: copy the app to releases/<version>, point current at it, restart, probe.
# A failed probe rolls back to the previous release and exits 1.
# Usage: scripts/deploy.sh VERSION [SOURCE_DIR]   (env: DEPLOY_HOST, DEPLOY_DIR, PORT, TASKPAD_TOKEN)
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/lib.sh"
version="${1:-}"
src="${2:-$here/..}"
if [ -z "$version" ]; then
  echo "usage: deploy.sh VERSION [SOURCE_DIR]" >&2
  exit 2
fi
case "$version" in
  *[!A-Za-z0-9._-]* | .* | "")
    echo "bad version: use letters, digits, dot, dash, underscore, not starting with a dot" >&2
    exit 2
    ;;
esac
if [ -z "${TASKPAD_TOKEN:-}" ]; then
  echo "TASKPAD_TOKEN must be set" >&2
  exit 2
fi

prev=$(run "cd '$DEPLOY_DIR' 2>/dev/null && readlink current || true")
echo "deploy: version $version to ${DEPLOY_HOST}:$DEPLOY_DIR (previous: ${prev:-none})"
run "mkdir -p '$DEPLOY_DIR/releases/$version' '$DEPLOY_DIR/data'" || exit 1
printf '%s\n' "$TASKPAD_TOKEN" | run "umask 077; cat > '$DEPLOY_DIR/token'" || exit 1
push "$src" "$DEPLOY_DIR/releases/$version" || exit 1
if [ -n "$prev" ]; then run "echo '$prev' > '$DEPLOY_DIR/previous'"; fi
run "ln -sfn 'releases/$version' '$DEPLOY_DIR/current'" || exit 1
restart

if "$here/probe.sh"; then
  echo "deploy OK: $version is live"
  exit 0
fi
echo "deploy FAILED: probe did not pass, rolling back"
"$here/rollback.sh"
exit 1
