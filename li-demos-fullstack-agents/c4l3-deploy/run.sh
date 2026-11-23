#!/usr/bin/env bash
# Lesson 4.1.3: Deploy to a small host. RUNS: the deploy script in local mode against a scratch directory on this machine: releases/,
# a current link, a 600-mode token file, a token that is not in the process list, a health probe, then a second version.
# SCRIPTED, NOT RUN: the same script over ssh to a real host (DEPLOY_HOST=user@host) and the live page in a browser.
# BLOCKED when agy has no quota: the deploy-script prompt.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
need_node || exit 1
new_workdir
copy_ms v1.0.0 "$WORK/app"
agy_step "$here/prompts/deploy-script.md" plan "$WORK/app"
deploy_env
cd "$WORK/app" || exit 1
say "deploy v1 to $DEPLOY_DIR on port $PORT"
scripts/deploy.sh v1 2>&1 | sed 's/^/  /'
if [ "${PIPESTATUS[0]}" -ne 0 ]; then echo "FAIL deploy v1"; exit 1; fi
say "what it left behind"
ls "$DEPLOY_DIR" | sed 's/^/  /'
echo "  current -> $(readlink "$DEPLOY_DIR/current")"
mode=$(stat -c %a "$DEPLOY_DIR/token")
echo "  token file mode: $mode"
if [ "$mode" != 600 ]; then echo "FAIL token file is not 600"; exit 1; fi
say "the token is not on any command line"
if ps -eo args | grep -F 'demo-token' | grep -v grep >/dev/null; then echo "FAIL the token is visible in ps"; exit 1; fi
echo "ok    not in ps output"
say "the live page (curl stands in for the browser)"
curl -fsS "http://127.0.0.1:$PORT/healthz"
echo
curl -fsS -o /dev/null -w '  page %{http_code}\n' "http://127.0.0.1:$PORT/"
say "deploy v2 over it; previous is recorded"
scripts/deploy.sh v2 2>&1 | sed 's/^/  /'
if [ "${PIPESTATUS[0]}" -ne 0 ]; then echo "FAIL deploy v2"; exit 1; fi
read -r prev <"$DEPLOY_DIR/previous"
echo "  current -> $(readlink "$DEPLOY_DIR/current"), previous -> $prev"
say "SSH STEP (scripted, not run): DEPLOY_HOST=user@host DEPLOY_DIR=/srv/taskpad TASKPAD_TOKEN=... scripts/deploy.sh v1"
