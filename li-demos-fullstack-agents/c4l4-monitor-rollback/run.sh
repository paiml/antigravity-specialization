#!/usr/bin/env bash
# Lesson 4.1.4: Monitoring and a rollback plan. RUNS: deploy v1, then deploy a v2 that does not start. The probe fails, the deploy rolls
# back by itself, v1 answers again. Then a manual rollback. The ssh variant is SCRIPTED, NOT RUN. BLOCKED when agy has no quota.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
need_node || exit 1
new_workdir
copy_ms v1.0.0 "$WORK/v1"
copy_ms v1.0.0 "$WORK/v2"
printf 'this is not javascript (\n' >>"$WORK/v2/main.js"
deploy_env
export PROBE_TRIES=8
cd "$WORK/v1" || exit 1
say "deploy v1"
scripts/deploy.sh v1 2>&1 | sed 's/^/  /'
if [ "${PIPESTATUS[0]}" -ne 0 ]; then echo "FAIL deploy v1"; exit 1; fi
say "deploy a broken v2 from a second copy (main.js has a syntax error)"
scripts/deploy.sh v2 "$WORK/v2" 2>&1 | sed 's/^/  /'
rc=${PIPESTATUS[0]}
echo "deploy exit code: $rc"
if [ "$rc" -ne 1 ]; then echo "FAIL a broken release did not fail the deploy"; exit 1; fi
say "after the automatic rollback"
echo "  current -> $(readlink "$DEPLOY_DIR/current")"
if [ "$(readlink "$DEPLOY_DIR/current")" != releases/v1 ]; then echo "FAIL current is not v1"; exit 1; fi
curl -fsS "http://127.0.0.1:$PORT/healthz" || { echo "FAIL v1 is not answering"; exit 1; }
echo
say "the log shows why v2 failed"
grep -m1 -E 'SyntaxError' "$DEPLOY_DIR/taskpad.log" | sed 's/^/  /'
say "manual rollback with nothing recorded must refuse"
rm -f "$DEPLOY_DIR/previous"
scripts/rollback.sh 2>&1 | sed 's/^/  /'
if [ "${PIPESTATUS[0]}" -eq 0 ]; then echo "FAIL rollback with no previous release succeeded"; exit 1; fi
echo "refused, as it must"
agy_step "$here/prompts/rollback-plan.md" plan "$WORK/v1"
