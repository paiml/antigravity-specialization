#!/usr/bin/env bash
# Probe: ask /healthz on the target until it answers ok, or give up. Exit 0 healthy, 1 not.
# Usage: scripts/probe.sh   (env: DEPLOY_HOST, PORT, PROBE_TRIES default 20)
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/lib.sh"
tries="${PROBE_TRIES:-20}"
url="$(probe_url)"
for i in $(seq 1 "$tries"); do
  if body=$(run "curl -fsS -m 2 '$url'" 2>/dev/null) && [ "$body" = '{"status":"ok"}' ]; then
    echo "probe OK after $i try(ies): $body"
    exit 0
  fi
  sleep 0.25
done
echo "probe FAILED after $tries tries: $url"
exit 1
