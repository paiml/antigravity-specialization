#!/usr/bin/env bash
# Shared by deploy.sh, rollback.sh and probe.sh. Source it; it sets no shell options.
# DEPLOY_HOST: "local" (default; runs on this machine) or an ssh target such as deploy@host.
# DEPLOY_DIR:  base directory on the target. Layout: releases/<version>, current -> releases/<version>,
#              data/, token (mode 600), taskpad.pid, taskpad.log, previous.
# PORT: port the app listens on. NODE: node binary on the target.
DEPLOY_HOST="${DEPLOY_HOST:-local}"
DEPLOY_DIR="${DEPLOY_DIR:-/srv/taskpad}"
PORT="${PORT:-3000}"
NODE="${NODE:-node}"
export PORT NODE

# run CMD: run a shell command on the target.
run() {
  if [ "$DEPLOY_HOST" = "local" ]; then
    bash -c "$1"
  else
    ssh -o BatchMode=yes "$DEPLOY_HOST" "$1"
  fi
}

# push SRC DEST: copy the files a release needs (a whitelist: no data, no tests, no node_modules) to DEST on the target.
push() {
  local item
  for item in main.js server.js db.js package.json migrations public scripts; do
    if [ "$DEPLOY_HOST" = "local" ]; then
      cp -R "$1/$item" "$2/"
    else
      scp -q -r "$1/$item" "$DEPLOY_HOST:$2/"
    fi
  done
}

# restart: stop the app if it runs, start current/scripts/start.sh detached, record the pid.
# The token is never on a command line: deploy.sh stores it in $DEPLOY_DIR/token and start.sh reads it.
restart() {
  run "cd '$DEPLOY_DIR' && if [ -f taskpad.pid ]; then kill \$(cat taskpad.pid) 2>/dev/null; rm -f taskpad.pid; fi; sleep 0.3; \
cd current || exit 1; PORT='$PORT' NODE='$NODE' nohup bash scripts/start.sh '$DEPLOY_DIR' >> '$DEPLOY_DIR/taskpad.log' 2>&1 < /dev/null & echo \$! > '$DEPLOY_DIR/taskpad.pid'"
}

# probe_url: the health URL as seen from the target.
probe_url() {
  echo "http://127.0.0.1:$PORT/healthz"
}
