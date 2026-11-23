#!/usr/bin/env bash
# Lesson 1.5: what fits on this machine. Free memory, model size on disk, and the capacity plan.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
echo "--- memory (MiB)"
free -m | awk 'NR==1 || /^Mem:/'
echo "--- the model we serve, size on disk"
ls -lL "$DEMO_MODEL" | awk '{printf "%.2f GiB  %s\n", $5/1073741824, $9}'
echo "--- apr serve plan (header-only, no weights loaded)"
apr serve plan "$DEMO_MODEL"
