#!/bin/bash
set -euo pipefail

case "${1:-}" in
    --test)
        [ "${STRICT_MODE:-0}" = "1" ] || { echo "FAIL: STRICT_MODE=1 required" >&2; exit 1; }
        echo "app.sh: unit test passed (STRICT_MODE=$STRICT_MODE)"
        ;;
    *)
        echo "app.sh: ready"
        ;;
esac
