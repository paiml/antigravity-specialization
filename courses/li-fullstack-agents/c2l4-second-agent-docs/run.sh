#!/usr/bin/env bash
# Lesson 2.1.4: Spawning a second agent for docs and examples. RUNS: every route in docs/API.md is called against the live server
# and must give the documented status; a doc that lists a route the server does not have is caught.
# BLOCKED when agy has no quota: the second session that writes the docs.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
need_node || exit 1
new_workdir
copy_ms ch2-done "$WORK/app"
agy_step "$here/prompts/write-docs.md" accept-edits "$WORK/app"
start_app "$WORK/app" demo-token || exit 1

# check_docs FILE: call every "## METHOD /path" heading in FILE and compare the status with the documented one.
check_docs() {
  local file="$1" method path want got url bad=0
  while read -r method path; do
    case "$method" in GET) want=200 ;; POST) want=201 ;; PATCH) want=200 ;; DELETE) want=204 ;; *) want=0 ;; esac
    url="$APP_URL$(echo "$path" | sed 's#:id#1#')"
    case "$path" in
      /api/tasks/:id) if [ "$method" = PATCH ]; then set -- -d '{"status":"doing"}'; else set --; fi ;;
      /api/tasks) if [ "$method" = POST ]; then set -- -d '{"title":"docs example"}'; else set --; fi ;;
      *) set -- ;;
    esac
    got=$(curl -sS -o /dev/null -w '%{http_code}' -X "$method" "$url" -H 'Authorization: Bearer demo-token' -H 'content-type: application/json' "$@")
    if [ "$got" = "$want" ]; then echo "ok    $method $path -> $got"; else echo "FAIL  $method $path -> $got (documented $want)"; bad=1; fi
  done < <(sed -nE 's/^## ([A-Z]+) (\/[^ ]*)$/\1 \2/p' "$file")
  return "$bad"
}

say "docs against the live server"
check_docs "$WORK/app/docs/API.md" || exit 1
say "a doc that lists a route the server does not have (must go red)"
cp "$WORK/app/docs/API.md" "$WORK/API.bad.md"
printf '\n## PUT /api/tasks/:id\n' >>"$WORK/API.bad.md"
if check_docs "$WORK/API.bad.md" >/dev/null; then echo "FAIL a made-up route passed"; exit 1; fi
echo "caught: PUT /api/tasks/:id is documented but not served"
