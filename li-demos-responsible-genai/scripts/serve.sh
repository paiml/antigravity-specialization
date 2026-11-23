#!/usr/bin/env bash
# Start the local model server on 127.0.0.1 and wait for /health. Stop it with scripts/stop.sh.
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
. "$here/lib/common.sh"
port="${DEMO_URL##*:}"
mkdir -p "$here/.run"
nohup apr serve run "$DEMO_MODEL" --port "$port" --no-gpu --offline >"$here/.run/serve.log" 2>&1 &
echo $! >"$here/.run/serve.pid"
for _ in $(seq 1 "${SERVE_WAIT:-60}"); do
  if curl -sS -m 2 "$DEMO_URL/health" >/dev/null 2>&1; then
    echo "server up on $DEMO_URL (pid $(cat "$here/.run/serve.pid"))"
    exit 0
  fi
  sleep 1
done
echo "server did not come up; see .run/serve.log" >&2
exit 1
