#!/usr/bin/env bash
# Lesson 2.1: the same question with no system prompt, a system prompt, and a constraint.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
need_server
q="Explain what a firewall does."
echo "=== 1. user only"
ask "" "$q" 80
echo
echo "=== 2. with a system prompt"
ask "You are a network security instructor. Answer for a beginner." "$q" 80
echo
echo "=== 3. with a constraint"
ask "You are a network security instructor. Answer in exactly one sentence of at most 20 words." "$q" 60
