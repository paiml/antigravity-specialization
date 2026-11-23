#!/usr/bin/env bash
# Stop the server started by scripts/serve.sh (kills only the recorded pid).
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
if [ -s "$here/.run/serve.pid" ]; then
  kill "$(cat "$here/.run/serve.pid")" 2>/dev/null || true
  echo "stopped"
else
  echo "no pid file"
fi
