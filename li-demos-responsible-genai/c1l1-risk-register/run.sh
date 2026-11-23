#!/usr/bin/env bash
# Lesson 1.1.1: a four-line risk register, one line per risk you will test in this course.
# RISK_DIR (default: out/ beside this script, git-ignored) holds the working directory.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
base="${RISK_DIR:-$here/out}"
mkdir -p "$base"
cd "$base" || exit 1
show mkdir -p responsible-ai
cd responsible-ai || exit 1
for r in wrong-answer unfair-answer hijacked-answer leaked-data; do echo "todo $r you -"; done >risks.md
show cat risks.md
show wc -l risks.md
