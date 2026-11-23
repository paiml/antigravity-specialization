#!/usr/bin/env bash
# Smoke test: start the server on a scratch port, ask /healthz, stop it.
# Usage: scripts/smoke.sh   (env: PORT, default 3100)
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
port="${PORT:-3100}"
node main.js >/dev/null 2>&1 &
pid=$!
trap 'kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null' EXIT
for _ in $(seq 1 50); do
  if body=$(curl -fsS "http://127.0.0.1:$port/healthz" 2>/dev/null); then
    echo "ok    health: $body"
    echo "smoke OK"
    exit 0
  fi
  sleep 0.1
done
echo "FAIL server did not come up"
exit 1
