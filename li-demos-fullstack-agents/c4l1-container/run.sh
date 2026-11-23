#!/usr/bin/env bash
# Lesson 4.1.1: Containerize the app. RUNS when docker works and the base image can be pulled: build, health check, a write that survives
# `docker restart` through a volume, and production mode refusing to start without a token. Prints DOCKER-BLOCKED and exits 0 when docker
# is missing or the daemon is not reachable. BLOCKED when agy has no quota: the Dockerfile prompt.
# Only containers and volumes named taskpad-demo-<pid> are created, and only those are removed.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
need_node || exit 1
new_workdir
DOCKER="${DOCKER:-docker}"
name="taskpad-demo-$$"
cleanup_docker() {
  "$DOCKER" rm -f "$name" >/dev/null 2>&1
  "$DOCKER" volume rm "$name-data" >/dev/null 2>&1
  "$DOCKER" rmi "$name" >/dev/null 2>&1
  return 0
}
trap 'cleanup_docker; cleanup_all' EXIT
copy_ms v1.0.0 "$WORK/app"
say "the Dockerfile"
cat "$WORK/app/Dockerfile"
agy_step "$here/prompts/dockerfile.md" accept-edits "$WORK/app"
if ! "$DOCKER" info >/dev/null 2>&1; then
  echo "DOCKER-BLOCKED: no docker daemon reachable"
  exit 0
fi
say "build"
if ! "$DOCKER" build -q -t "$name" "$WORK/app" >"$WORK/build.out" 2>&1; then
  tail -n 5 "$WORK/build.out" | sed 's/^/  /'
  if grep -qiE 'resolve source metadata|pull access|dial tcp|no such host|timeout|network' "$WORK/build.out"; then
    echo "DOCKER-BLOCKED: the base image could not be pulled"
    exit 0
  fi
  echo "FAIL docker build"
  exit 1
fi
echo "built $name"
port=$(free_port)
"$DOCKER" run -d --name "$name" -p "127.0.0.1:$port:3000" -v "$name-data:/data" -e TASKPAD_TOKEN=demo-token "$name" >/dev/null || exit 1
for _ in $(seq 1 50); do
  if curl -fsS "http://127.0.0.1:$port/healthz" >/dev/null 2>&1; then break; fi
  sleep 0.2
done
say "health"
curl -fsS "http://127.0.0.1:$port/healthz" || { echo "FAIL not healthy"; exit 1; }
echo
for _ in $(seq 1 40); do
  st=$("$DOCKER" inspect --format '{{.State.Health.Status}}' "$name")
  if [ "$st" = healthy ]; then break; fi
  sleep 0.5
done
echo "container health status: $st"
if [ "$st" != healthy ]; then echo "FAIL not healthy"; exit 1; fi
say "write, restart the container, read it back (the volume keeps the data)"
curl -sS -o /dev/null -X POST "http://127.0.0.1:$port/api/tasks" -H 'Authorization: Bearer demo-token' -H 'content-type: application/json' -d '{"title":"survives a restart"}'
"$DOCKER" restart "$name" >/dev/null
for _ in $(seq 1 50); do
  if curl -fsS "http://127.0.0.1:$port/healthz" >/dev/null 2>&1; then break; fi
  sleep 0.2
done
body=$(curl -fsS "http://127.0.0.1:$port/api/tasks")
echo "  $body"
case "$body" in *'survives a restart'*) echo "ok    the task is still there" ;; *) echo "FAIL the task was lost"; exit 1 ;; esac
say "production mode without a token refuses to start"
"$DOCKER" run --rm "$name" 2>&1 | sed 's/^/  /'
"$DOCKER" run --rm "$name" >/dev/null 2>&1
rc=$?
echo "exit code: $rc"
if [ "$rc" -ne 1 ]; then echo "FAIL expected exit 1"; exit 1; fi
say "the image runs as a non-root user"
who=$("$DOCKER" exec "$name" id -un)
echo "  user: $who"
if [ "$who" = root ]; then echo "FAIL runs as root"; exit 1; fi
