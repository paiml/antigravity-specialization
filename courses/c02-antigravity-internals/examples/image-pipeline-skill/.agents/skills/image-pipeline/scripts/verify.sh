#!/bin/bash
# The verification loop. Run this after the pipeline and it either agrees or
# it fails -- it does not print an opinion.
#
# It exists because the obvious check is not enough. Asserting the output is
# 460x502 passes on a transpose AND on a 90-degree rotation, which are
# different images. So this checks the pixels, not the shape:
#
#   1. the output is 460x502                      (shape)
#   2. transposing it back reproduces stage 1     (it really is a transpose)
#   3. it is NOT what -rotate 90 would have made  (it is not the other one)

set -euo pipefail

INPUT_FILE="${1:-pyramid-star.png}"
OUTPUT_FILE="${2:-out.png}"

if command -v magick >/dev/null 2>&1; then
    IM_CONVERT=(magick)
    IM_IDENTIFY=(magick identify)
    IM_COMPARE=(magick compare)
elif command -v convert >/dev/null 2>&1; then
    IM_CONVERT=(convert)
    IM_IDENTIFY=(identify)
    IM_COMPARE=(compare)
else
    echo "error: ImageMagick not found; need 'magick' (IM7) or 'convert' (IM6)" >&2
    exit 127
fi

for f in "$INPUT_FILE" "$OUTPUT_FILE"; do
    [ -f "$f" ] || { echo "error: no such file: $f" >&2; exit 1; }
done

HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
FAILED=0

check() {
    if [ "$2" = "$3" ]; then
        echo "  PASS  $1"
    else
        echo "  FAIL  $1"
        echo "        expected [$3], got [$2]"
        FAILED=$((FAILED + 1))
    fi
}

# ae A B -- absolute pixel difference. compare exits 1 when images differ,
# which is not an error here, so the exit code is swallowed and only the
# number is read. Different-sized images are compared on their overlap and
# do NOT error, which is exactly why check 1 measures the shape separately.
ae() {
    "${IM_COMPARE[@]}" -metric AE "$1" "$2" null: 2>&1 | awk '{print $1}' || true
}

IN_WH="$("${IM_IDENTIFY[@]}" -format '%wx%h' "$INPUT_FILE")"
OUT_WH="$("${IM_IDENTIFY[@]}" -format '%wx%h' "$OUTPUT_FILE")"
WANT_WH="$(echo "$IN_WH" | awk -Fx '{print $2 "x" $1}')"

echo "verifying $OUTPUT_FILE against $INPUT_FILE ($IN_WH)"

check "output is the transposed shape" "$OUT_WH" "$WANT_WH"

"$HERE/remove_star.sh" "$INPUT_FILE" "$WORK/stage1.png" >/dev/null
"$HERE/transpose.sh" "$OUTPUT_FILE" "$WORK/back.png" >/dev/null
check "transposing back reproduces stage 1" "$(ae "$WORK/stage1.png" "$WORK/back.png")" "0"

"${IM_CONVERT[@]}" "$WORK/stage1.png" -rotate 90 +repage "$WORK/rotated.png"
if [ "$(ae "$OUTPUT_FILE" "$WORK/rotated.png")" = "0" ]; then
    echo "  FAIL  output is a rotation, not a transpose"
    echo "        -rotate 90 and -transpose both give $WANT_WH; this one took the wrong branch"
    FAILED=$((FAILED + 1))
else
    echo "  PASS  output is not the -rotate 90 result ($(ae "$OUTPUT_FILE" "$WORK/rotated.png") pixels differ)"
fi

echo
if [ "$FAILED" -eq 0 ]; then
    echo "OK -- 3 checks passed."
    exit 0
fi
echo "$FAILED check(s) failed."
exit 1
