#!/usr/bin/env bash
# One real agy run, recorded once. Output goes to the terminal and to files.
# RUN is the run directory: prompt.md in it, the agent works in RUN/work.
RUN=${RUN:-$PWD}
cd "$RUN/work" || exit 1
CMD=(agy --sandbox --mode accept-edits --dangerously-skip-permissions --model gemini-4-neon-high --print "$(cat "$RUN"/prompt.md)")
printf '%q ' "${CMD[@]:0:8}" > "$RUN"/command.txt; echo '"$(cat prompt.md)"' >> "$RUN"/command.txt
date -u +%Y-%m-%dT%H:%M:%SZ > "$RUN"/utc.txt
env -u SSH_CONNECTION -u SSH_CLIENT -u SSH_TTY timeout 1500 "${CMD[@]}" </dev/null 2> "$RUN"/stderr.txt | tee "$RUN"/stdout.txt
echo "${PIPESTATUS[0]}" > "$RUN"/exit.txt
git diff > "$RUN"/patch.diff
echo "AGY-EXIT $(cat "$RUN"/exit.txt)"
