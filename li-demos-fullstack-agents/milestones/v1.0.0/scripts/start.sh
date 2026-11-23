#!/usr/bin/env bash
# Start the app from a release directory. Called by deploy.sh on the target.
# Usage: scripts/start.sh BASE   (BASE holds the "token" file and the data directory)
set -euo pipefail
base="${1:?usage: start.sh BASE}"
read -r TASKPAD_TOKEN <"$base/token"
export TASKPAD_TOKEN
export NODE_ENV=production
export DB_PATH="$base/data/taskpad.db"
exec "${NODE:-node}" main.js
