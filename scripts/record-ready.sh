#!/usr/bin/env bash
# record-ready.sh — verify each course chapter demo in antigravity-specialization.
#
# Usage:
#   bash scripts/record-ready.sh              # check this repository
#   bash scripts/record-ready.sh <root>       # check an explicit repo root
#   bash scripts/record-ready.sh --self-test  # verify failure & skip modes
#
# Prints one line per chapter:
#   CHAPTER <name>: PASS|FAIL|SKIP(<reason>) <seconds>s
# Exits non-zero if any chapter fails or if no chapters are found (anti-vacuity).

set -u
set -o pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SELF="$SELF_DIR/$(basename "${BASH_SOURCE[0]}")"
DEFAULT_ROOT="$(cd "$SELF_DIR/.." && pwd)"

TMP_WORK=""
SELFTEST_T=""

cleanup() {
    if [ -n "${TMP_WORK:-}" ] && [ -d "$TMP_WORK" ]; then
        rm -rf "$TMP_WORK"
    fi
    if [ -n "${SELFTEST_T:-}" ] && [ -d "$SELFTEST_T" ]; then
        rm -rf "$SELFTEST_T"
    fi
}
trap cleanup EXIT

toml_list_dirs() { # file section
    awk -v target="$2" '
        {
            line = $0
            sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line)
            if (line == "" || substr(line, 1, 1) == "#") next
            if (line ~ /^\[\[[A-Za-z0-9_]+\]\]$/) {
                s = substr(line, 3, length(line) - 4)
                in_target = (s == target)
                next
            }
            if (substr(line, 1, 1) == "[") { in_target = 0; next }
            if (in_target) {
                p = index(line, "=")
                if (p > 0) {
                    k = substr(line, 1, p - 1); sub(/[ \t]+$/, "", k)
                    if (k == "dir") {
                        v = substr(line, p + 1); sub(/^[ \t]+/, "", v)
                        if (length(v) >= 2 && substr(v, 1, 1) == "\"" && substr(v, length(v), 1) == "\"") {
                            print substr(v, 2, length(v) - 2)
                        }
                    }
                }
            }
        }
    ' "$1"
}

toml_get_field() { # file section key
    awk -v target="$2" -v key="$3" '
        {
            line = $0
            sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line)
            if (line == "" || substr(line, 1, 1) == "#") next
            if (line ~ /^\[[A-Za-z0-9_]+\]$/) {
                s = substr(line, 2, length(line) - 2)
                in_target = (s == target)
                next
            }
            if (substr(line, 1, 1) == "[") { in_target = 0; next }
            if (in_target) {
                p = index(line, "=")
                if (p > 0) {
                    k = substr(line, 1, p - 1); sub(/[ \t]+$/, "", k)
                    if (k == key) {
                        v = substr(line, p + 1); sub(/^[ \t]+/, "", v)
                        if (length(v) >= 2 && substr(v, 1, 1) == "\"" && substr(v, length(v), 1) == "\"") {
                            print substr(v, 2, length(v) - 2)
                            exit
                        }
                    }
                }
            }
        }
    ' "$1"
}

run_step() { # log_file cmd...
    local log_file=$1
    shift
    "$@" >"$log_file" 2>&1
}

run_chapter() { # root cdir edir
    local root=$1 cdir=$2 edir=$3
    local cshort course_prefix eshort chapter ex_dir ex_toml run_cmd
    local t0 log_file status rc im_cmd

    cshort="${cdir#courses/}"
    course_prefix="${cshort%%-*}"
    eshort="${edir#examples/}"
    chapter="${course_prefix}/${eshort}"
    ex_dir="$root/$cdir/$edir"
    ex_toml="$ex_dir/example.toml"

    t0=${SECONDS:-0}
    log_file="$TMP_WORK/chapter-${course_prefix}-${eshort}.log"
    : > "$log_file"
    status=""
    rc=0

    if [ ! -d "$ex_dir" ] || [ ! -f "$ex_toml" ]; then
        status="FAIL(no demo)"
        rc=1
    else
        run_cmd=$(toml_get_field "$ex_toml" example run || true)
        if [ -z "$run_cmd" ]; then
            status="FAIL(no demo)"
            rc=1
        else
            case "$chapter" in
                c01/complex-image-processing)
                    if run_step "$log_file" bash -c 'cd "$1" && ./remove_star.sh pyramid-star.png "$2" && test -s "$2"' _ "$ex_dir" "$TMP_WORK/c01-out.png"; then
                        status="PASS"
                    else
                        status="FAIL"
                        rc=1
                    fi
                    ;;
                c02/grill-me-first|c02/explore-and-plan|c02/image-pipeline-skill)
                    # Interactive (-i) or live Antigravity CLI (agy) only.
                    status="SKIP(live)"
                    ;;
                c02/transpose-image)
                    if run_step "$log_file" bash -c 'cd "$1" && ./transpose.sh nostar.png "$2" && test -s "$2"' _ "$ex_dir" "$TMP_WORK/c02-transpose-out.png"; then
                        status="PASS"
                    else
                        status="FAIL"
                        rc=1
                    fi
                    ;;
                c02/image-pipeline)
                    if run_step "$log_file" bash -c 'cd "$1" && ./pipeline.sh pyramid-star.png "$2" && ./verify.sh pyramid-star.png "$2"' _ "$ex_dir" "$TMP_WORK/c02-pipeline-out.png"; then
                        status="PASS"
                    else
                        status="FAIL"
                        rc=1
                    fi
                    ;;
                c02/batch-runner)
                    im_cmd=""
                    if command -v convert >/dev/null 2>&1; then
                        im_cmd='convert {} -transpose +repage {}.t.png'
                    elif command -v magick >/dev/null 2>&1; then
                        im_cmd='magick {} -transpose +repage {}.t.png'
                    fi
                    if [ -z "$im_cmd" ]; then
                        printf 'error: ImageMagick (convert or magick) not found\n' >"$log_file"
                        status="FAIL"
                        rc=1
                    else
                        mkdir -p "$TMP_WORK/batch"
                        rm -rf "$TMP_WORK/batch/images"
                        cp -r "$ex_dir/images" "$TMP_WORK/batch/images"
                        if run_step "$log_file" bash -c '
                            set -euo pipefail
                            cd "$1"
                            cargo test -p batch-runner
                            cd "$2"
                            cargo run --manifest-path "$1/Cargo.toml" --bin batch-runner -- --dir images --cmd "$3"
                            test -s "$2/images/pyramid-a.png.t.png"
                            test -s "$2/images/pyramid-b.png.t.png"
                        ' _ "$ex_dir" "$TMP_WORK/batch" "$im_cmd"; then
                            status="PASS"
                        else
                            status="FAIL"
                            rc=1
                        fi
                    fi
                    ;;
                c02/pmat-review-agent)
                    if run_step "$log_file" bash -c 'cd "$1" && ./verify.sh' _ "$ex_dir"; then
                        status="PASS"
                    else
                        status="FAIL"
                        rc=1
                    fi
                    ;;
                *)
                    status="FAIL(no demo)"
                    rc=1
                    ;;
            esac
        fi
    fi

    report_chapter "$chapter" "$status" "$t0" "$rc" "$log_file"
}

report_chapter() { # chapter status t0 rc log_file
    local chapter=$1 status=$2 t0=$3 rc=$4 log_file=$5
    local elapsed=$(( ${SECONDS:-0} - t0 ))
    printf 'CHAPTER %s: %s %ds\n' "$chapter" "$status" "$elapsed"
    if [ "$rc" -ne 0 ] && [ -s "$log_file" ]; then
        PFX="  [$chapter] " awk '{ print ENVIRON["PFX"] $0 }' "$log_file" >&2
    fi
    return "$rc"
}

run_c04_module() { # root mod
    local root=$1 mod=$2
    local c4_dir="$root/c04-falsify-the-agent"
    local mod_dir="$c4_dir/$mod"
    local gate_sh="$c4_dir/scripts/gate.sh"
    local chapter="c04/$mod"
    local t0 log_file status rc

    t0=${SECONDS:-0}
    log_file="$TMP_WORK/chapter-c04-${mod}.log"
    : > "$log_file"
    status=""
    rc=0

    if [ ! -d "$mod_dir" ] || [ ! -f "$mod_dir/Cargo.toml" ]; then
        status="FAIL(no demo)"
        rc=1
    elif [ ! -f "$gate_sh" ]; then
        printf 'error: missing %s\n' "$gate_sh" >"$log_file"
        status="FAIL"
        rc=1
    elif run_step "$log_file" bash "$gate_sh" "$mod"; then
        status="PASS"
    else
        status="FAIL"
        rc=1
    fi

    report_chapter "$chapter" "$status" "$t0" "$rc" "$log_file"
}

run_all() { # root
    local root=$1
    local spec_toml="$root/specialization.toml"
    local cdir edir
    local total_chapters=0 fails=0
    local -a courses=()
    local -a examples=()

    TMP_WORK=$(mktemp -d)

    if [ ! -f "$spec_toml" ]; then
        printf 'error: specialization.toml not found under %s\n' "$root" >&2
        return 1
    fi

    mapfile -t courses < <(toml_list_dirs "$spec_toml" courses)
    if [ "${#courses[@]}" -eq 0 ]; then
        printf 'error: anti-vacuity: 0 courses found in %s\n' "$spec_toml" >&2
        return 1
    fi

    for cdir in "${courses[@]}"; do
        [ -n "$cdir" ] || continue
        local ctoml="$root/$cdir/course.toml"
        if [ ! -f "$ctoml" ]; then
            printf 'error: missing course.toml at %s\n' "$ctoml" >&2
            fails=$((fails + 1))
            continue
        fi
        examples=()
        mapfile -t examples < <(toml_list_dirs "$ctoml" examples)
        if [ "${#examples[@]}" -eq 0 ]; then
            printf 'error: anti-vacuity: 0 examples found in %s\n' "$ctoml" >&2
            fails=$((fails + 1))
            continue
        fi
        for edir in "${examples[@]}"; do
            [ -n "$edir" ] || continue
            total_chapters=$((total_chapters + 1))
            if ! run_chapter "$root" "$cdir" "$edir"; then
                fails=$((fails + 1))
            fi
        done
    done

    if [ -d "$root/c04-falsify-the-agent" ]; then
        local c4_dir="$root/c04-falsify-the-agent"
        local -a c4_mods=()
        local mod_path mod
        for mod_path in "$c4_dir"/m[0-9]*/; do
            [ -d "$mod_path" ] || continue
            mod_path=${mod_path%/}
            c4_mods+=("${mod_path##*/}")
        done
        if [ "${#c4_mods[@]}" -eq 0 ]; then
            printf 'error: anti-vacuity: 0 modules found in %s\n' "$c4_dir" >&2
            fails=$((fails + 1))
        else
            for mod in "${c4_mods[@]}"; do
                total_chapters=$((total_chapters + 1))
                if ! run_c04_module "$root" "$mod"; then
                    fails=$((fails + 1))
                fi
            done
        fi
    fi

    if [ "$total_chapters" -eq 0 ]; then
        printf 'error: anti-vacuity: 0 chapters checked\n' >&2
        return 1
    fi
    if [ "$fails" -gt 0 ]; then
        return 1
    fi
    return 0
}

self_test() {
    local st_pass=0 st_fail=0
    local d out rc

    SELFTEST_T=$(mktemp -d)

    st_check() { # name dir expect_rc want_substr
        local name=$1 dir=$2 expect_rc=$3 want=$4
        out=$("$SELF" "$dir" 2>&1)
        rc=$?
        if [ "$expect_rc" = "0" ] && [ "$rc" -ne 0 ]; then
            printf '  FAIL  %-24s expected exit 0, got %d\n' "$name" "$rc"
            st_fail=$((st_fail + 1))
        elif [ "$expect_rc" = "nz" ] && [ "$rc" -eq 0 ]; then
            printf '  FAIL  %-24s expected non-zero exit, got 0\n' "$name"
            st_fail=$((st_fail + 1))
        elif [ -n "$want" ] && ! printf '%s' "$out" | grep -Fq -- "$want"; then
            printf '  FAIL  %-24s missing [%s] in output\n' "$name" "$want"
            st_fail=$((st_fail + 1))
        else
            printf '  ok    %-24s %s\n' "$name" "${want:-exit $rc}"
            st_pass=$((st_pass + 1))
        fi
    }

    # 1. Anti-vacuity: 0 courses must fail.
    d="$SELFTEST_T/empty"
    mkdir -p "$d"
    printf '[specialization]\nslug = "x"\n' > "$d/specialization.toml"
    st_check "anti-vacuity" "$d" "nz" "anti-vacuity"

    # 2. Missing demo must print FAIL(no demo) and exit non-zero.
    d="$SELFTEST_T/nodemo"
    mkdir -p "$d/courses/c99-test/examples/missing-demo"
    printf '[[courses]]\ndir = "courses/c99-test"\n' > "$d/specialization.toml"
    printf '[[examples]]\ndir = "examples/missing-demo"\n' > "$d/courses/c99-test/course.toml"
    st_check "no-demo" "$d" "nz" "CHAPTER c99/missing-demo: FAIL(no demo)"

    # 3. Live-agy-only demo must print SKIP(live) and exit 0.
    d="$SELFTEST_T/live"
    mkdir -p "$d/courses/c02-antigravity-internals/examples/grill-me-first"
    cp -a "$DEFAULT_ROOT/courses/c02-antigravity-internals/examples/grill-me-first/." \
        "$d/courses/c02-antigravity-internals/examples/grill-me-first/"
    printf '[[courses]]\ndir = "courses/c02-antigravity-internals"\n' > "$d/specialization.toml"
    printf '[[examples]]\ndir = "examples/grill-me-first"\n' > "$d/courses/c02-antigravity-internals/course.toml"
    st_check "live-skip" "$d" "0" "CHAPTER c02/grill-me-first: SKIP(live)"

    # 4. Failing runnable demo must print FAIL, prefix stderr safely, and exit non-zero.
    d="$SELFTEST_T/faildemo"
    mkdir -p "$d/courses/c01-the-antigravity-platform/examples/complex-image-processing"
    cp -a "$DEFAULT_ROOT/courses/c01-the-antigravity-platform/examples/complex-image-processing/." \
        "$d/courses/c01-the-antigravity-platform/examples/complex-image-processing/"
    printf '#!/usr/bin/env bash\necho "boom" >&2\nexit 1\n' > \
        "$d/courses/c01-the-antigravity-platform/examples/complex-image-processing/remove_star.sh"
    chmod +x "$d/courses/c01-the-antigravity-platform/examples/complex-image-processing/remove_star.sh"
    printf '[[courses]]\ndir = "courses/c01-the-antigravity-platform"\n' > "$d/specialization.toml"
    printf '[[examples]]\ndir = "examples/complex-image-processing"\n' > "$d/courses/c01-the-antigravity-platform/course.toml"
    st_check "failing-demo" "$d" "nz" "CHAPTER c01/complex-image-processing: FAIL"
    st_check "failing-demo-log" "$d" "nz" "  [c01/complex-image-processing] boom"

    # 5. Passing runnable demo must print PASS and exit 0.
    d="$SELFTEST_T/passdemo"
    mkdir -p "$d/courses/c01-the-antigravity-platform/examples/complex-image-processing"
    cp -a "$DEFAULT_ROOT/courses/c01-the-antigravity-platform/examples/complex-image-processing/." \
        "$d/courses/c01-the-antigravity-platform/examples/complex-image-processing/"
    printf '#!/usr/bin/env bash\nprintf "ok\\n" > "$2"\n' > \
        "$d/courses/c01-the-antigravity-platform/examples/complex-image-processing/remove_star.sh"
    chmod +x "$d/courses/c01-the-antigravity-platform/examples/complex-image-processing/remove_star.sh"
    printf '[[courses]]\ndir = "courses/c01-the-antigravity-platform"\n' > "$d/specialization.toml"
    printf '[[examples]]\ndir = "examples/complex-image-processing"\n' > "$d/courses/c01-the-antigravity-platform/course.toml"
    st_check "passing-demo" "$d" "0" "CHAPTER c01/complex-image-processing: PASS"

    # 6. Empty c04-falsify-the-agent directory must fail anti-vacuity.
    d="$SELFTEST_T/c04-empty"
    mkdir -p "$d/courses/c02-antigravity-internals/examples/grill-me-first" "$d/c04-falsify-the-agent"
    cp -a "$DEFAULT_ROOT/courses/c02-antigravity-internals/examples/grill-me-first/." \
        "$d/courses/c02-antigravity-internals/examples/grill-me-first/"
    printf '[[courses]]\ndir = "courses/c02-antigravity-internals"\n' > "$d/specialization.toml"
    printf '[[examples]]\ndir = "examples/grill-me-first"\n' > "$d/courses/c02-antigravity-internals/course.toml"
    st_check "c04-anti-vacuity" "$d" "nz" "anti-vacuity: 0 modules found"

    # 7. Failing c04 module must print FAIL, prefix stderr safely, and exit non-zero.
    d="$SELFTEST_T/c04-fail"
    mkdir -p "$d/courses/c02-antigravity-internals/examples/grill-me-first" \
        "$d/c04-falsify-the-agent/m1" "$d/c04-falsify-the-agent/scripts"
    cp -a "$DEFAULT_ROOT/courses/c02-antigravity-internals/examples/grill-me-first/." \
        "$d/courses/c02-antigravity-internals/examples/grill-me-first/"
    printf '[[courses]]\ndir = "courses/c02-antigravity-internals"\n' > "$d/specialization.toml"
    printf '[[examples]]\ndir = "examples/grill-me-first"\n' > "$d/courses/c02-antigravity-internals/course.toml"
    : > "$d/c04-falsify-the-agent/m1/Cargo.toml"
    printf '#!/usr/bin/env bash\necho "c04-boom" >&2\nexit 1\n' > "$d/c04-falsify-the-agent/scripts/gate.sh"
    chmod +x "$d/c04-falsify-the-agent/scripts/gate.sh"
    st_check "c04-failing-mod" "$d" "nz" "CHAPTER c04/m1: FAIL"
    st_check "c04-failing-log" "$d" "nz" "  [c04/m1] c04-boom"

    # 8. Passing c04 module must print PASS and exit 0.
    d="$SELFTEST_T/c04-pass"
    mkdir -p "$d/courses/c02-antigravity-internals/examples/grill-me-first" \
        "$d/c04-falsify-the-agent/m1" "$d/c04-falsify-the-agent/scripts"
    cp -a "$DEFAULT_ROOT/courses/c02-antigravity-internals/examples/grill-me-first/." \
        "$d/courses/c02-antigravity-internals/examples/grill-me-first/"
    printf '[[courses]]\ndir = "courses/c02-antigravity-internals"\n' > "$d/specialization.toml"
    printf '[[examples]]\ndir = "examples/grill-me-first"\n' > "$d/courses/c02-antigravity-internals/course.toml"
    : > "$d/c04-falsify-the-agent/m1/Cargo.toml"
    printf '#!/usr/bin/env bash\nexit 0\n' > "$d/c04-falsify-the-agent/scripts/gate.sh"
    chmod +x "$d/c04-falsify-the-agent/scripts/gate.sh"
    st_check "c04-passing-mod" "$d" "0" "CHAPTER c04/m1: PASS"

    printf '\nself-test: %d ok, %d failed\n' "$st_pass" "$st_fail"
    [ "$st_fail" -eq 0 ]
}

case "${1:-}" in
    --self-test) self_test ;;
    --help|-h)   sed -n '2,12p' "$SELF" ;;
    *)           run_all "$(cd "${1:-$DEFAULT_ROOT}" && pwd)" ;;
esac
