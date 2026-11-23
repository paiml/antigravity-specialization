#!/usr/bin/env bash
# Smoke test: start the server on a scratch port and database, walk the whole API with curl, stop it.
# Usage: scripts/smoke.sh   (env: PORT, default 3100)
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
port="${PORT:-3100}"
work=$(mktemp -d)
token="smoke-token"
base="http://127.0.0.1:$port"
fail=0
PORT="$port" DB_PATH="$work/smoke.db" TASKPAD_TOKEN="$token" node main.js >"$work/out.log" 2>"$work/err.log" &
pid=$!
cleanup() {
  kill "$pid" 2>/dev/null
  wait "$pid" 2>/dev/null
  rm -rf -- "${work:?}"
}
trap cleanup EXIT

up=0
for _ in $(seq 1 50); do
  if curl -fsS "$base/healthz" >/dev/null 2>&1; then
    up=1
    break
  fi
  sleep 0.1
done
if [ "$up" -ne 1 ]; then
  echo "FAIL server did not come up"
  cat "$work/err.log"
  exit 1
fi

# check NAME WANT_CODE curl-args... : print the status and compare with the wanted one.
check() {
  local name="$1" want="$2"
  shift 2
  local got
  got=$(curl -sS -o "$work/body.json" -w '%{http_code}' "$@")
  if [ "$got" = "$want" ]; then
    echo "ok    $name ($got)"
  else
    echo "FAIL  $name (got $got, want $want)"
    fail=1
  fi
}
auth="authorization: Bearer $token"
json="content-type: application/json"

check "health" 200 "$base/healthz"
check "list is empty and open" 200 "$base/api/tasks"
check "create without a token is refused" 401 -X POST -H "$json" -d '{"title":"x"}' "$base/api/tasks"
check "create" 201 -X POST -H "$auth" -H "$json" -d '{"title":"first task"}' "$base/api/tasks"
check "empty title is refused" 400 -X POST -H "$auth" -H "$json" -d '{"title":"  "}' "$base/api/tasks"
check "move to doing" 200 -X PATCH -H "$auth" -H "$json" -d '{"status":"doing"}' "$base/api/tasks/1"
check "bad status is refused" 400 -X PATCH -H "$auth" -H "$json" -d '{"status":"nope"}' "$base/api/tasks/1"
check "filter by status" 200 "$base/api/tasks?status=doing"
check "unknown id" 404 -X PATCH -H "$auth" -H "$json" -d '{"status":"done"}' "$base/api/tasks/99"
check "delete" 204 -X DELETE -H "$auth" "$base/api/tasks/1"

if [ "$fail" -ne 0 ]; then
  echo "smoke FAILED"
  exit 1
fi
echo "smoke OK"
