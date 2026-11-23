#!/usr/bin/env bash
# Shared helpers for the lesson demos. Source this file; it sets no shell options.
DEMO_ROOT="${DEMO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
AGY_BIN="${AGY_BIN:-agy}"
export DEMO_ROOT AGY_BIN

# say TEXT: a banner line so the capture reads like a script.
say() { echo "--- $*"; }

# need_node: Node 22 or newer (node:sqlite). Looks in the usual nvm location when the default is older.
need_node() {
  local major
  major=$(node --version 2>/dev/null | sed -E 's/^v([0-9]+).*/\1/')
  if [ "${major:-0}" -ge 22 ]; then return 0; fi
  local cand
  for cand in "$HOME"/.nvm/versions/node/v22*/bin "$HOME"/.nvm/versions/node/v23*/bin "$HOME"/.nvm/versions/node/v24*/bin; do
    if [ -x "$cand/node" ]; then
      PATH="$cand:$PATH"
      export PATH
      return 0
    fi
  done
  echo "Node 22 or newer is required (found: $(node --version 2>&1))" >&2
  return 1
}

# new_workdir: make a scratch directory, remember it, remove it on exit.
new_workdir() {
  WORK=$(mktemp -d)
  export WORK
  trap cleanup_all EXIT
}

# deploy_env: point the deploy scripts at a scratch directory on this machine (needs new_workdir first).
deploy_env() {
  DEPLOY_HOST=local
  DEPLOY_DIR="$WORK/srv"
  PORT=$(free_port)
  TASKPAD_TOKEN=demo-token
  export DEPLOY_HOST DEPLOY_DIR PORT TASKPAD_TOKEN
}

# stop_deployed: stop the app that the deploy scripts started, if any.
stop_deployed() {
  local pid
  if [ -n "${DEPLOY_DIR:-}" ] && [ -f "$DEPLOY_DIR/taskpad.pid" ]; then
    read -r pid <"$DEPLOY_DIR/taskpad.pid"
    kill "$pid" 2>/dev/null
  fi
  return 0
}

# cleanup_all: stop what the lesson started, then remove the scratch directory.
cleanup_all() {
  stop_app
  stop_deployed
  if [ -n "${WORK:-}" ]; then rm -rf -- "${WORK:?}"; fi
}

# copy_ms NAME DEST: copy a milestone of Taskpad into DEST.
copy_ms() {
  mkdir -p "$2"
  cp -R "$DEMO_ROOT/milestones/$1/." "$2/"
}

# free_port: print a port that nothing listens on right now.
free_port() {
  node -e "const s=require('node:net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close();});"
}

# start_app DIR TOKEN: run DIR/main.js in the background on a free port with a scratch database.
# Sets APP_PORT, APP_PID, APP_LOG, APP_URL. Waits until /healthz answers (up to 5 s).
start_app() {
  local dir="$1" token="$2" i
  APP_PORT=$(free_port)
  APP_LOG="$dir/app.log"
  APP_URL="http://127.0.0.1:$APP_PORT"
  (cd "$dir" && PORT="$APP_PORT" DB_PATH="$dir/data/taskpad.db" TASKPAD_TOKEN="$token" exec node main.js >"$dir/app.out" 2>"$APP_LOG") &
  APP_PID=$!
  export APP_PORT APP_PID APP_LOG APP_URL
  for i in $(seq 1 50); do
    if curl -fsS "$APP_URL/healthz" >/dev/null 2>&1; then return 0; fi
    sleep 0.1
  done
  echo "app did not come up; log:" >&2
  cat "$APP_LOG" >&2
  return 1
}

# stop_app: stop the app started by start_app, if any.
stop_app() {
  if [ -n "${APP_PID:-}" ]; then
    kill "$APP_PID" 2>/dev/null
    wait "$APP_PID" 2>/dev/null
    APP_PID=""
  fi
  return 0
}

# hold_open: with HOLD set, keep the app up for a browser until Enter is pressed (record day). Otherwise do nothing.
hold_open() {
  if [ -n "${HOLD:-}" ]; then
    say "serving at ${APP_URL:-?} (HOLD is set): press Enter to stop"
    read -r _ || true
  fi
  return 0
}

# agy_step PROMPT_FILE MODE [DIR]: run one prompt through the installed agy CLI (print mode) in DIR.
# Prints the prompt, then either the real reply or a BLOCKED line. Never logs in, never types credentials.
# A quota or auth failure prints "AGY-BLOCKED: <first error line>" and returns 0 with AGY_RC=3 (callers go on with repo-side steps; AGY_RC holds 3).
# AGY_STATE (a file) remembers a block so later lessons in one capture session do not retry.
agy_step() {
  local prompt="$1" mode="${2:-plan}" dir="${3:-$PWD}" out rc
  say "agent prompt ($(basename "$prompt"), mode $mode)"
  sed 's/^/  | /' "$prompt"
  if [ -n "${AGY_STATE:-}" ] && [ -s "$AGY_STATE" ]; then
    echo "AGY-BLOCKED: $(head -n 1 "$AGY_STATE") (not retried in this session)"
    AGY_RC=3
    return 0
  fi
  out=$(cd "$dir" && "$AGY_BIN" --print="$(cat "$prompt")" --mode "$mode" --print-timeout 300s 2>&1)
  rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "AGY-BLOCKED: exit $rc: $(echo "$out" | head -n 1)"
    if [ -n "${AGY_STATE:-}" ]; then echo "$out" | head -n 1 >"$AGY_STATE"; fi
    AGY_RC=3
    return 0
  fi
  echo "$out" | sed 's/^/  > /'
  return 0
}

# seed_bug_title DIR: the kind of mistake an agent makes. The trimmed title is checked, but the untrimmed one is stored.
seed_bug_title() {
  cp "$1/server.js" "$1/server.js.orig"
  sed -i 's|return { value };|return { value: raw };|' "$1/server.js"
}

# seed_bug_board DIR: a front end mistake. A prefix match files "done" tasks under "doing".
seed_bug_board() {
  cp "$1/public/board.js" "$1/public/board.js.orig"
  sed -i 's|groups\[t.status\].push(t);|groups[STATUSES.find((s) => s.startsWith(t.status.slice(0, 2)))].push(t);|' "$1/public/board.js"
}

# fix_bug FILE: undo a seeded bug by restoring FILE from FILE.orig, showing the diff first.
fix_bug() {
  diff -u "$1" "$1.orig" | sed 's/^/  /'
  mv "$1.orig" "$1"
}

# sql DBFILE ARGS...: the sqlite3 shell on a scratch database file, with fixed statements written in the lesson script.
sql() {
  local db="$1"
  shift
  sqlite3 "$db" "$@"
}

# json_field JSON PATH: print one field with node (no jq needed on a student machine).
json_field() {
  node -e "const o=JSON.parse(process.argv[1]);const v=process.argv[2].split('.').reduce((a,k)=>a[k],o);console.log(v);" "$1" "$2"
}

# http_code ARGS...: curl, print only the status code, body to \$WORK/body.json when WORK is set.
http_code() {
  curl -sS -o "${WORK:-/tmp}/body.json" -w '%{http_code}' "$@"
}

# expect_code NAME WANT ARGS...: curl once, print "ok" or "FAIL" with the status; return 1 on a mismatch.
expect_code() {
  local name="$1" want="$2" got
  shift 2
  got=$(http_code "$@")
  if [ "$got" = "$want" ]; then
    echo "ok    $name ($got)"
  else
    echo "FAIL  $name (got $got, want $want)"
    return 1
  fi
}
