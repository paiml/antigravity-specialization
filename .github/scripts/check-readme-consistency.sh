#!/usr/bin/env bash
# check-readme-consistency.sh — cross-check every generated README in this
# repository against the TOML file it was generated from.
#
# WHY THIS EXISTS
#
# Every README here is build output. `specialization.toml`, each `course.toml`
# and each `example.toml` are the sources; the README beside each of them is
# rendered from it. The generator lives outside this repository and cannot run
# in this repository's CI — a pull request from a fork gets no credentials, and
# this gate has to work for one. So this script never regenerates anything.
#
# THE OBVIOUS IMPLEMENTATION IS A GATE THAT CANNOT FAIL. Committing a checksum
# of each README beside it and diffing looks like drift detection and is not:
# whoever hand-edits a README updates the checksum in the same commit, and the
# check goes green having confirmed that a file matches a hash of itself.
# Nothing below compares a README against a stored hash of that README.
#
# What this does instead is cross-validate. Each README makes claims that its
# TOML also states — a title, a tagline, a description, one table row per
# entry, a link target, an image, a footer naming its own source file — and
# every one of those claims is checked against the data. A hand-edit cannot
# forge that by updating a stored hash, because the comparison is against the
# source of truth. To make a reworded title pass you must reword the TOML too,
# and at that point the TOML is what shipped and the next render agrees.
#
# WHAT THIS DOES NOT CATCH — read this before trusting it
#
#   * Prose reworded INSIDE a field's value, consistently on both sides. Edit
#     `tagline` in the TOML and the README line rendered from it to the same
#     new wording and this script sees two files that agree, because they do.
#     Only running the real generator would notice the README was never
#     re-rendered. This is a CONSISTENCY CHECK, NOT A REGENERATE-AND-DIFF, and
#     this case is the whole of the difference.
#   * Layout the generator would produce differently but that no rule below
#     names: column ordering in a table header, blank-line placement,
#     punctuation the script does not read.
#   * A README section with no counterpart in the TOML. `requires` is checked
#     TOML→README only, so a requirements line invented in a README, for a
#     field the TOML does not have, is invisible.
#   * Anything in a file that no TOML points at. The anti-vacuity arm catches
#     an unreferenced README; it does not catch, say, a stray image.
#
# CALLED BY .github/workflows/gate.yml. Also runnable by hand:
#
#     .github/scripts/check-readme-consistency.sh             # check this repo
#     .github/scripts/check-readme-consistency.sh --self-test # watch it fail
#
# THE MUTATION THAT MUST TURN THIS RED
#
# Reword the H1 of any README without touching its TOML. `--self-test` does
# exactly that, plus a dropped table row, a deleted footer, a broken link, a
# blown length cap, a deleted course image, TOML this script cannot parse, an
# unclaimed README and an empty tree — each against a throwaway copy, each
# asserted to be reported. If any arm stops failing, this has stopped being a
# gate. CI runs `--self-test` BEFORE the real check, so a checker that has
# quietly gone blind reds the build instead of passing it.
#
# Pure bash plus the coreutils/find/awk/sed every runner already has. No
# package install, no third-party action, no interpreter beyond the shell.

set -euo pipefail

# ---------------------------------------------------------------------------
# Field-length caps.
#
# These are THIS SCRIPT's caps, not necessarily the generator's — the generator
# is not readable from here, so its exact limits cannot be quoted and are not
# claimed. They sit well above every value currently in the tree and exist to
# catch the hand-edit that drops a paragraph into a field that renders as one
# cell of a markdown table. A value inside these is not thereby blessed by the
# generator.
# ---------------------------------------------------------------------------
CAP_SLUG=64
CAP_DIR=128
CAP_TITLE=80
CAP_TAGLINE=80
CAP_SUMMARY=100
CAP_DESCRIPTION=400
CAP_RUN=200
CAP_REQUIRES=200
CAP_NOTE=80

# The generator stamps this footer on every README it writes, naming the file
# it rendered from. A README without it is not a generated README any more.
FOOTER_HEAD='<sub>Generated — do not edit by hand. Edit `'
FOOTER_TAIL='` and re-render.</sub>'

PROBLEMS=0
CHECKED_SPECIALIZATION=0
CHECKED_COURSES=0
CHECKED_EXAMPLES=0
CHECKED_READMES=0
SPEC_SLUG=""
SPEC_TITLE=""

bad() {
    printf '  FAIL  %s\n        %s\n' "$1" "$2"
    PROBLEMS=$((PROBLEMS + 1))
}

# Compare what a README states against what its TOML states.
eq() { # where what readme_value toml_value
    if [ "$3" != "$4" ]; then
        bad "$1" "$2 — README says [$3], TOML says [$4]"
    fi
}

cap() { # where field value max
    local n=${#3}
    if [ "$n" -gt "$4" ]; then
        bad "$1" "$2 is $n chars, over this script's cap of $4"
    fi
}

# ---------------------------------------------------------------------------
# TOML reading.
#
# Shell parses TOML badly, so this does not pretend to parse TOML. It flattens
# the small, flat, generated shape these files actually have and REFUSES
# anything else — a multi-line string, an inline array or table, a dotted or
# quoted key, an escape, a literal tab, a key outside a table. A parser that
# quietly reads the wrong value is worse than one that stops, so every
# unsupported construct is a hard error naming file and line, never a silently
# skipped line.
#
# Output: one TAB-separated row per key,
#     section <TAB> index <TAB> key <TAB> value
# where index is the 0-based position within an `[[array]]` of tables.
# ---------------------------------------------------------------------------
toml_flatten() {
    awk -v file="$1" '
    BEGIN { q3 = sprintf("%c%c%c", 39, 39, 39) }
    function die(msg) {
        printf("unsupported TOML at %s:%d — %s", file, NR, msg)
        exit 2
    }
    {
        line = $0
        sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line)
        if (line == "" || substr(line, 1, 1) == "#") next

        if (line ~ /^\[\[[A-Za-z0-9_]+\]\]$/) {
            s = substr(line, 3, length(line) - 4)
            count[s]++; sect = s; idx = count[s] - 1; next
        }
        if (line ~ /^\[[A-Za-z0-9_]+\]$/) {
            sect = substr(line, 2, length(line) - 2); idx = 0; next
        }
        if (substr(line, 1, 1) == "[") die("unsupported table header: " line)
        if (sect == "") die("key outside any table: " line)

        p = index(line, "=")
        if (p == 0) die("not a `key = value` line: " line)
        k = substr(line, 1, p - 1); sub(/[ \t]+$/, "", k)
        v = substr(line, p + 1);   sub(/^[ \t]+/, "", v)

        if (k !~ /^[A-Za-z0-9_]+$/) die("unsupported key syntax: " k)
        if (substr(v, 1, 3) == "\"\"\"" || substr(v, 1, 3) == q3)
            die("multi-line strings are not supported")
        if (substr(v, 1, 1) == "[" || substr(v, 1, 1) == "{")
            die("inline arrays and tables are not supported")

        if (length(v) >= 2 && substr(v, 1, 1) == "\"" && substr(v, length(v), 1) == "\"") {
            v = substr(v, 2, length(v) - 2)
            if (index(v, "\\") > 0) die("backslash escapes are not supported")
            if (index(v, "\"") > 0) die("embedded double quote is not supported")
        } else if (v ~ /^[0-9]+$/) {
            # a bare integer, kept as written
        } else {
            die("value must be a one-line double-quoted string or an integer: " v)
        }
        if (index(v, "\t") > 0) die("literal tab in a value is not supported")

        printf("%s\t%d\t%s\t%s\n", sect, idx, k, v)
    }' "$1"
}

# Read one value out of a flattened TOML. Prints nothing and returns 1 when the
# key is absent; callers treat an absent key and an empty value alike, and
# report both as missing.
tget() { # flatfile section index key
    awk -F'\t' -v s="$2" -v i="$3" -v k="$4" '
        $1 == s && $2 == i && $3 == k { print $4; found = 1; exit }
        END { exit(found ? 0 : 1) }' "$1"
}

# How many entries an `[[array]]` of tables has.
tcount() { # flatfile section
    awk -F'\t' -v s="$2" '
        $1 == s { seen = 1; if ($2 + 0 > max) max = $2 + 0 }
        END { print (seen ? max + 1 : 0) }' "$1"
}

# ---------------------------------------------------------------------------
# README reading.
# ---------------------------------------------------------------------------
h1_count()  { grep -c '^# ' "$1" || true; }
h1_lineno() { awk '/^# / { print NR; exit }' "$1"; }
h1_text()   { awk '/^# / { sub(/^# /, ""); print; exit }' "$1"; }

# The Nth non-blank line strictly after line START. This is how the tagline and
# the description are located: the generator puts them directly after the
# heading, so a paragraph inserted by hand displaces them and is caught.
nonblank_after() { # file start n
    awk -v start="$2" -v n="$3" 'NR > start && NF > 0 { c++; if (c == n) { print; exit } }' "$1"
}

last_nonblank() { awk 'NF > 0 { l = $0 } END { print l }' "$1"; }

table_linenos() { awk '/^\|/ { print NR }' "$1"; }

# Table body rows: everything after the header and the `|---|` separator.
table_rows() { awk '/^\|/ { n++; if (n > 2) print }' "$1"; }

# Cell I (1-based) of a `| a | b |` row.
cell() { # row index
    printf '%s\n' "$1" | awk -F'|' -v i="$2" '{
        v = $(i + 1); gsub(/^[ \t]+|[ \t]+$/, "", v); print v }'
}

# A table cell of the form [`text`](href) — the shape the generator emits for
# every link in every table. Prints text then href, one per line; prints
# nothing at all when the cell is not that shape.
link_cell() { # cell
    printf '%s\n' "$1" | sed -n 's/^\[`\([^`]*\)`\](\([^)]*\))$/\1\n\2/p'
}

# Exactly one contiguous markdown table, with a real separator row. A table
# with a header and zero rows is allowed here on purpose: the row count is
# compared against the TOML by the caller, which gives a better message than
# "no rows" when the last row is deleted by hand.
check_one_table() { # where file
    local -a nums=()
    local i prev sep
    mapfile -t nums < <(table_linenos "$2")
    if [ "${#nums[@]}" -lt 2 ]; then
        bad "$1" "expected a markdown table; found ${#nums[@]} table line(s)"
        return 1
    fi
    prev=${nums[0]}
    for ((i = 1; i < ${#nums[@]}; i++)); do
        if [ "${nums[$i]}" -ne $((prev + 1)) ]; then
            bad "$1" "expected exactly one table; table lines are not contiguous (line ${nums[$i]} follows $prev)"
            return 1
        fi
        prev=${nums[$i]}
    done
    sep=$(sed -n "${nums[1]}p" "$2")
    if ! printf '%s\n' "$sep" | grep -Eq '^\|[ :|-]+\|$'; then
        bad "$1" "second table line is not a separator row: [$sep]"
        return 1
    fi
    return 0
}

# The footer names the file this README was rendered from, relative to the
# repository root. That is a claim about which source owns this README, so it
# is compared, not merely presence-tested.
check_footer() { # where file toml_relpath
    local want last
    want="${FOOTER_HEAD}${3}${FOOTER_TAIL}"
    last=$(last_nonblank "$2")
    if [ "$last" != "$want" ]; then
        bad "$1" "generated-footer line is missing or wrong
        want: $want
        got:  $last"
    fi
}

# Plain filenames from .gitignore — build output that may sit in a worktree
# without belonging in any README's file table.
ignored_names() { # root
    if [ -f "$1/.gitignore" ]; then
        grep -v '^[[:space:]]*#' "$1/.gitignore" | grep -v '[/*?]' | sed '/^[[:space:]]*$/d' || true
    fi
}

# ---------------------------------------------------------------------------
# The checks.
# ---------------------------------------------------------------------------
check_specialization() { # root flat readme
    local root=$1 flat=$2 rm=$3
    local where="README.md"
    local title tagline desc slug n i hl h1n
    local -a rows=()

    slug=$(tget "$flat" specialization 0 slug || true)
    title=$(tget "$flat" specialization 0 title || true)
    tagline=$(tget "$flat" specialization 0 tagline || true)
    desc=$(tget "$flat" specialization 0 description || true)

    [ -n "$slug" ]    || bad "specialization.toml" "required field [specialization].slug is missing or empty"
    [ -n "$title" ]   || bad "specialization.toml" "required field [specialization].title is missing or empty"
    [ -n "$tagline" ] || bad "specialization.toml" "required field [specialization].tagline is missing or empty"
    [ -n "$desc" ]    || bad "specialization.toml" "required field [specialization].description is missing or empty"

    cap "specialization.toml" "[specialization].slug"        "$slug"    "$CAP_SLUG"
    cap "specialization.toml" "[specialization].title"       "$title"   "$CAP_TITLE"
    cap "specialization.toml" "[specialization].tagline"     "$tagline" "$CAP_TAGLINE"
    cap "specialization.toml" "[specialization].description" "$desc"    "$CAP_DESCRIPTION"

    h1n=$(h1_count "$rm")
    if [ "$h1n" != "1" ]; then
        bad "$where" "expected exactly one '# ' heading, found $h1n"
    else
        eq "$where" "H1" "$(h1_text "$rm")" "$title"
        hl=$(h1_lineno "$rm")
        eq "$where" "tagline line"     "$(nonblank_after "$rm" "$hl" 1)" "$tagline"
        eq "$where" "description line" "$(nonblank_after "$rm" "$hl" 2)" "$desc"
    fi

    n=$(tcount "$flat" courses)
    if [ "$n" -eq 0 ]; then
        bad "specialization.toml" "no [[courses]] entries — a specialization with no courses is not a shape this repo has"
        return
    fi

    if check_one_table "$where" "$rm"; then
        mapfile -t rows < <(table_rows "$rm")
        if [ "${#rows[@]}" -ne "$n" ]; then
            bad "$where" "Courses table has ${#rows[@]} rows, specialization.toml has $n [[courses]] entries"
        fi
    fi

    for ((i = 0; i < n; i++)); do
        local dir cflat ctagline cnum row c_num c_link c_covers text href
        local -a link=()
        ctagline=""; cnum=""
        dir=$(tget "$flat" courses "$i" dir || true)
        if [ -z "$dir" ]; then
            bad "specialization.toml" "[[courses]] entry $i has no dir"
            continue
        fi
        cap "specialization.toml" "[[courses]].dir" "$dir" "$CAP_DIR"
        if [ ! -d "$root/$dir" ]; then
            bad "specialization.toml" "[[courses]] entry $i points at $dir, which does not exist on disk"
            continue
        fi
        if [ ! -f "$root/$dir/course.toml" ]; then
            bad "specialization.toml" "[[courses]] entry $i names $dir, which has no course.toml"
            continue
        fi
        printf '%s\n' "$dir" >> "$LISTED_COURSES"

        # The row's "what it covers" cell is the course's OWN tagline, so the
        # specialization README is checked against the course's TOML rather
        # than against a copy of it kept in specialization.toml.
        cflat=$(mktemp)
        if toml_flatten "$root/$dir/course.toml" > "$cflat" 2>/dev/null; then
            ctagline=$(tget "$cflat" course 0 tagline || true)
            cnum=$(tget "$cflat" course 0 number || true)
        fi
        rm -f "$cflat"

        [ "$i" -lt "${#rows[@]}" ] || continue
        row=${rows[$i]}
        c_num=$(cell "$row" 1)
        c_link=$(cell "$row" 2)
        c_covers=$(cell "$row" 3)

        eq "$where" "Courses row $((i + 1)) number column" "$c_num" "${cnum:-<missing>}"
        eq "$where" "Courses row $((i + 1)) what-it-covers" "$c_covers" "${ctagline:-<missing>}"

        mapfile -t link < <(link_cell "$c_link")
        if [ "${#link[@]}" -ne 2 ]; then
            bad "$where" "Courses row $((i + 1)) link cell is not [\`path\`](path): [$c_link]"
        else
            text=${link[0]}; href=${link[1]}
            eq "$where" "Courses row $((i + 1)) link target" "$href" "$dir"
            if [ "$text" != "$href" ]; then
                bad "$where" "Courses row $((i + 1)) link text [$text] does not match its target [$href]"
            fi
            if [ ! -e "$root/$href" ]; then
                bad "$where" "Courses row $((i + 1)) links to $href, which does not exist on disk"
            fi
        fi
    done

    CHECKED_SPECIALIZATION=1
    CHECKED_READMES=$((CHECKED_READMES + 1))
}

check_course() { # root dir
    local root=$1 dir=$2
    local ct="$root/$dir/course.toml" rm="$root/$dir/README.md"
    local where="$dir/README.md"
    local flat slug title tagline desc spec num n i h1n hl
    local img_line img_src img_w img_alt raw want_backlink
    local disk only_disk
    local -a rows=()

    if [ ! -f "$rm" ]; then bad "$dir" "course.toml has no README.md beside it"; return; fi
    printf '%s\n' "$rm" >> "$OWNED_READMES"

    flat=$(mktemp)
    if ! toml_flatten "$ct" > "$flat" 2>&1; then
        bad "$dir/course.toml" "$(cat "$flat")"
        return
    fi

    slug=$(tget "$flat" course 0 slug || true)
    title=$(tget "$flat" course 0 title || true)
    tagline=$(tget "$flat" course 0 tagline || true)
    desc=$(tget "$flat" course 0 description || true)
    spec=$(tget "$flat" course 0 specialization || true)
    num=$(tget "$flat" course 0 number || true)

    [ -n "$slug" ]    || bad "$dir/course.toml" "required field [course].slug is missing or empty"
    [ -n "$title" ]   || bad "$dir/course.toml" "required field [course].title is missing or empty"
    [ -n "$tagline" ] || bad "$dir/course.toml" "required field [course].tagline is missing or empty"
    [ -n "$desc" ]    || bad "$dir/course.toml" "required field [course].description is missing or empty"
    [ -n "$spec" ]    || bad "$dir/course.toml" "required field [course].specialization is missing or empty"
    [ -n "$num" ]     || bad "$dir/course.toml" "required field [course].number is missing or empty"

    cap "$dir/course.toml" "[course].slug"        "$slug"    "$CAP_SLUG"
    cap "$dir/course.toml" "[course].title"       "$title"   "$CAP_TITLE"
    cap "$dir/course.toml" "[course].tagline"     "$tagline" "$CAP_TAGLINE"
    cap "$dir/course.toml" "[course].description" "$desc"    "$CAP_DESCRIPTION"

    # slug names the directory; it is not free text.
    if [ -n "$slug" ] && [ "$slug" != "$(basename "$dir")" ]; then
        bad "$dir/course.toml" "[course].slug is [$slug] but the directory is named [$(basename "$dir")]"
    fi
    if [ -n "$spec" ] && [ "$spec" != "$SPEC_SLUG" ]; then
        bad "$dir/course.toml" "[course].specialization is [$spec] but specialization.toml declares slug [$SPEC_SLUG]"
    fi
    if [ -n "$num" ]; then
        case "$num" in
            *[!0-9]*) bad "$dir/course.toml" "[course].number is [$num], not a whole number" ;;
        esac
    fi

    # The course image. The <img> is present exactly when the file it points at
    # is, and carries the course title as its alt text — so deleting the image
    # without re-rendering, and renaming the course without re-rendering, both
    # surface here.
    img_line=$(grep -n '<img ' "$rm" | head -1 || true)
    if [ -f "$root/$dir/assets/course-image.png" ]; then
        [ -n "$img_line" ] || bad "$where" "assets/course-image.png exists but the README has no <img>"
    else
        [ -z "$img_line" ] || bad "$where" "README carries an <img> but assets/course-image.png is not on disk"
    fi
    if [ -n "$img_line" ]; then
        raw=${img_line#*:}
        img_src=$(printf '%s\n' "$raw" | sed -n 's/.*<img[^>]*src="\([^"]*\)".*/\1/p')
        img_w=$(printf '%s\n'   "$raw" | sed -n 's/.*<img[^>]*width="\([^"]*\)".*/\1/p')
        img_alt=$(printf '%s\n' "$raw" | sed -n 's/.*<img[^>]*alt="\([^"]*\)".*/\1/p')
        [ "$img_src" = "assets/course-image.png" ] || bad "$where" "<img src> is [$img_src], expected [assets/course-image.png]"
        [ "$img_w" = "160" ] || bad "$where" "<img width> is [$img_w], expected [160]"
        eq "$where" "<img alt>" "$img_alt" "$title"
        if [ -n "$img_src" ] && [ ! -e "$root/$dir/$img_src" ]; then
            bad "$where" "<img src> points at $img_src, which does not exist on disk"
        fi
    fi

    h1n=$(h1_count "$rm")
    if [ "$h1n" != "1" ]; then
        bad "$where" "expected exactly one '# ' heading, found $h1n"
    else
        eq "$where" "H1" "$(h1_text "$rm")" "$title"
        hl=$(h1_lineno "$rm")
        eq "$where" "tagline line"     "$(nonblank_after "$rm" "$hl" 1)" "$tagline"
        eq "$where" "description line" "$(nonblank_after "$rm" "$hl" 2)" "$desc"
    fi

    want_backlink="Part of the [$SPEC_TITLE](../..) specialization."
    if ! grep -Fqx "$want_backlink" "$rm"; then
        bad "$where" "missing or wrong specialization back-link
        want: $want_backlink"
    fi

    check_footer "$where" "$rm" "$dir/course.toml"

    n=$(tcount "$flat" examples)
    if [ "$n" -eq 0 ]; then
        bad "$dir/course.toml" "no [[examples]] entries — a course with no examples is not a shape this repo has"
        CHECKED_COURSES=$((CHECKED_COURSES + 1))
        CHECKED_READMES=$((CHECKED_READMES + 1))
        return
    fi

    if check_one_table "$where" "$rm"; then
        mapfile -t rows < <(table_rows "$rm")
        if [ "${#rows[@]}" -ne "$n" ]; then
            bad "$where" "Examples table has ${#rows[@]} rows, course.toml has $n [[examples]] entries"
        fi
    fi

    : > "$LISTED_EXAMPLES"
    for ((i = 0; i < n; i++)); do
        local edir etitle esum row c_link c_does text href
        local -a link=()
        edir=$(tget "$flat" examples "$i" dir || true)
        etitle=$(tget "$flat" examples "$i" title || true)
        esum=$(tget "$flat" examples "$i" summary || true)

        if [ -z "$edir" ]; then bad "$dir/course.toml" "[[examples]] entry $i has no dir"; continue; fi
        [ -n "$etitle" ] || bad "$dir/course.toml" "[[examples]] entry $i has no title"
        [ -n "$esum" ]   || bad "$dir/course.toml" "[[examples]] entry $i has no summary"
        cap "$dir/course.toml" "[[examples]].dir"     "$edir"   "$CAP_DIR"
        cap "$dir/course.toml" "[[examples]].title"   "$etitle" "$CAP_TITLE"
        cap "$dir/course.toml" "[[examples]].summary" "$esum"   "$CAP_SUMMARY"

        if [ "$i" -lt "${#rows[@]}" ]; then
            row=${rows[$i]}
            c_link=$(cell "$row" 1)
            c_does=$(cell "$row" 2)
            eq "$where" "Examples row $((i + 1)) what-it-does" "$c_does" "${esum:-<missing>}"
            mapfile -t link < <(link_cell "$c_link")
            if [ "${#link[@]}" -ne 2 ]; then
                bad "$where" "Examples row $((i + 1)) link cell is not [\`path\`](path): [$c_link]"
            else
                text=${link[0]}; href=${link[1]}
                eq "$where" "Examples row $((i + 1)) link target" "$href" "$edir"
                if [ "$text" != "$href" ]; then
                    bad "$where" "Examples row $((i + 1)) link text [$text] does not match its target [$href]"
                fi
                if [ ! -e "$root/$dir/$href" ]; then
                    bad "$where" "Examples row $((i + 1)) links to $href, which does not exist on disk"
                fi
            fi
        fi

        if [ ! -d "$root/$dir/$edir" ]; then
            bad "$dir/course.toml" "[[examples]] entry $i points at $edir, which does not exist on disk"
            continue
        fi
        printf '%s\n' "$edir" >> "$LISTED_EXAMPLES"
        check_example "$root" "$dir" "$edir" "$etitle" "$esum"
    done

    # Every example directory on disk is listed, and nothing else is.
    disk=$(mktemp)
    if [ -d "$root/$dir/examples" ]; then
        find "$root/$dir/examples" -mindepth 1 -maxdepth 1 -type d | sed "s|^$root/$dir/||" | sort > "$disk"
    else
        : > "$disk"
    fi
    sort -u -o "$LISTED_EXAMPLES" "$LISTED_EXAMPLES"
    only_disk=$(comm -13 "$LISTED_EXAMPLES" "$disk")
    if [ -n "$only_disk" ]; then
        bad "$dir/course.toml" "example directories on disk that course.toml does not list: $(printf '%s' "$only_disk" | tr '\n' ' ')"
    fi

    CHECKED_COURSES=$((CHECKED_COURSES + 1))
    CHECKED_READMES=$((CHECKED_READMES + 1))
}

check_example() { # root coursedir exampledir title_from_course summary_from_course
    local root=$1 cdir=$2 edir=$3 want_title=$4 want_summary=$5
    local base="$cdir/$edir"
    local et="$root/$base/example.toml" rm="$root/$base/README.md"
    local where="$base/README.md"
    local flat title summary desc run requires n i h1n hl block
    local listed disk ignore extra
    local -a rows=()

    if [ ! -f "$et" ]; then bad "$base" "example directory has no example.toml"; return; fi
    if [ ! -f "$rm" ]; then bad "$base" "example.toml has no README.md beside it"; return; fi
    printf '%s\n' "$rm" >> "$OWNED_READMES"

    flat=$(mktemp)
    if ! toml_flatten "$et" > "$flat" 2>&1; then
        bad "$base/example.toml" "$(cat "$flat")"
        return
    fi

    title=$(tget "$flat" example 0 title || true)
    summary=$(tget "$flat" example 0 summary || true)
    desc=$(tget "$flat" example 0 description || true)
    run=$(tget "$flat" example 0 run || true)
    requires=$(tget "$flat" example 0 requires || true)

    [ -n "$title" ]   || bad "$base/example.toml" "required field [example].title is missing or empty"
    [ -n "$summary" ] || bad "$base/example.toml" "required field [example].summary is missing or empty"
    [ -n "$desc" ]    || bad "$base/example.toml" "required field [example].description is missing or empty"
    [ -n "$run" ]     || bad "$base/example.toml" "required field [example].run is missing or empty"

    cap "$base/example.toml" "[example].title"       "$title"    "$CAP_TITLE"
    cap "$base/example.toml" "[example].summary"     "$summary"  "$CAP_SUMMARY"
    cap "$base/example.toml" "[example].description" "$desc"     "$CAP_DESCRIPTION"
    cap "$base/example.toml" "[example].run"         "$run"      "$CAP_RUN"
    cap "$base/example.toml" "[example].requires"    "$requires" "$CAP_REQUIRES"

    # The course lists this example by title and summary; the example states
    # its own. Two files, one fact — so a title reworded in one of them is
    # caught even though neither README prints it next to the other.
    if [ "$title" != "$want_title" ]; then
        bad "$base/example.toml" "[example].title is [$title] but $cdir/course.toml lists it as [$want_title]"
    fi
    if [ "$summary" != "$want_summary" ]; then
        bad "$base/example.toml" "[example].summary is [$summary] but $cdir/course.toml lists it as [$want_summary]"
    fi

    h1n=$(h1_count "$rm")
    if [ "$h1n" != "1" ]; then
        bad "$where" "expected exactly one '# ' heading, found $h1n"
    else
        eq "$where" "H1" "$(h1_text "$rm")" "$title"
        hl=$(h1_lineno "$rm")
        eq "$where" "description line" "$(nonblank_after "$rm" "$hl" 1)" "$desc"
    fi

    # The ```bash block under ## Run is the `run` field, verbatim.
    block=$(awk '/^```bash$/ { inb = 1; next } /^```$/ { if (inb) exit } inb { print }' "$rm")
    eq "$where" "## Run command block" "$block" "$run"

    if [ -n "$requires" ] && ! grep -Fqx "$requires" "$rm"; then
        bad "$where" "[example].requires is not present as a line in the README
        want: $requires"
    fi

    check_footer "$where" "$rm" "$base/example.toml"

    CHECKED_EXAMPLES=$((CHECKED_EXAMPLES + 1))
    CHECKED_READMES=$((CHECKED_READMES + 1))

    n=$(tcount "$flat" files)
    if [ "$n" -eq 0 ]; then
        bad "$base/example.toml" "no [[files]] entries — an example that lists no files is not a shape this repo has"
        return
    fi

    listed=$(mktemp)
    if check_one_table "$where" "$rm"; then
        mapfile -t rows < <(table_rows "$rm")
        if [ "${#rows[@]}" -ne "$n" ]; then
            bad "$where" "files table has ${#rows[@]} rows, example.toml has $n [[files]] entries"
        fi
    fi
    for ((i = 0; i < n; i++)); do
        local fpath fnote row c_path c_note shown
        fpath=$(tget "$flat" files "$i" path || true)
        fnote=$(tget "$flat" files "$i" note || true)
        if [ -z "$fpath" ]; then bad "$base/example.toml" "[[files]] entry $i has no path"; continue; fi
        cap "$base/example.toml" "[[files]].note" "$fnote" "$CAP_NOTE"
        printf '%s\n' "$fpath" >> "$listed"
        if [ ! -e "$root/$base/$fpath" ]; then
            bad "$base/example.toml" "[[files]] entry $i names $fpath, which does not exist on disk"
        fi
        [ "$i" -lt "${#rows[@]}" ] || continue
        row=${rows[$i]}
        c_path=$(cell "$row" 1)
        c_note=$(cell "$row" 2)
        shown=$(printf '%s\n' "$c_path" | sed -n 's/^`\([^`]*\)`$/\1/p')
        if [ -z "$shown" ]; then
            bad "$where" "files row $((i + 1)) first cell is not \`path\`: [$c_path]"
        else
            eq "$where" "files row $((i + 1)) path" "$shown" "$fpath"
            if [ ! -e "$root/$base/$shown" ]; then
                bad "$where" "files row $((i + 1)) names $shown, which does not exist on disk"
            fi
        fi
        eq "$where" "files row $((i + 1)) note" "$c_note" "$fnote"
    done

    # Anything shipped in the example directory that no [[files]] entry names.
    # README.md and example.toml are the generated pair itself; dotfiles and
    # .gitignore'd names are build output, not example material.
    disk=$(mktemp); ignore=$(mktemp)
    find "$root/$base" -mindepth 1 -maxdepth 1 -type f -printf '%f\n' \
        | grep -vx 'README.md' | grep -vx 'example.toml' | grep -v '^\.' | sort > "$disk" || true
    ignored_names "$root" | sort > "$ignore"
    sort -u -o "$listed" "$listed"
    extra=$(comm -13 "$listed" "$disk" | comm -23 - "$ignore")
    if [ -n "$extra" ]; then
        bad "$base/example.toml" "files in the example directory that no [[files]] entry lists: $(printf '%s' "$extra" | tr '\n' ' ')"
    fi
}

# ---------------------------------------------------------------------------
run_checks() { # root
    local root=$1
    local st srm flat disk only_disk all unowned
    local -a dirs=()
    local d

    printf 'README consistency — generated READMEs cross-checked against their TOML\n'
    printf 'root: %s\n\n' "$root"

    WORK=$(mktemp -d)
    trap 'rm -rf "${WORK:?}"' EXIT
    export TMPDIR="$WORK"
    LISTED_COURSES="$WORK/listed-courses"
    LISTED_EXAMPLES="$WORK/listed-examples"
    OWNED_READMES="$WORK/owned-readmes"
    : > "$LISTED_COURSES"; : > "$LISTED_EXAMPLES"; : > "$OWNED_READMES"

    st="$root/specialization.toml"
    srm="$root/README.md"
    if [ ! -f "$st" ]; then
        bad "specialization.toml" "not found at the repository root"
    elif [ ! -f "$srm" ]; then
        bad "README.md" "specialization.toml has no README.md beside it"
    else
        flat=$(mktemp)
        if ! toml_flatten "$st" > "$flat" 2>&1; then
            bad "specialization.toml" "$(cat "$flat")"
        else
            SPEC_SLUG=$(tget "$flat" specialization 0 slug || true)
            SPEC_TITLE=$(tget "$flat" specialization 0 title || true)
            printf '%s\n' "$srm" >> "$OWNED_READMES"
            check_footer "README.md" "$srm" "specialization.toml"
            check_specialization "$root" "$flat" "$srm"

            mapfile -t dirs < <(sort -u "$LISTED_COURSES")
            for d in "${dirs[@]}"; do
                [ -n "$d" ] || continue
                check_course "$root" "$d"
            done

            # Every course directory on disk is listed, and nothing else is.
            disk=$(mktemp)
            if [ -d "$root/courses" ]; then
                find "$root/courses" -mindepth 1 -maxdepth 1 -type d | sed "s|^$root/||" | sort > "$disk"
            else
                : > "$disk"
            fi
            sort -u -o "$LISTED_COURSES" "$LISTED_COURSES"
            only_disk=$(comm -13 "$LISTED_COURSES" "$disk")
            if [ -n "$only_disk" ]; then
                bad "specialization.toml" "course directories on disk that specialization.toml does not list: $(printf '%s' "$only_disk" | tr '\n' ' ')"
            fi
        fi
    fi

    # -----------------------------------------------------------------------
    # ANTI-VACUITY. A checker that finds nothing must FAIL, not congratulate
    # itself. Zero TOMLs, too few READMEs, or a README that no TOML claims are
    # each a hard failure — those are exactly the states in which every check
    # above is trivially satisfied because none of them ran.
    # -----------------------------------------------------------------------
    printf '\nchecked: specialization=%d courses=%d examples=%d readmes=%d\n' \
        "$CHECKED_SPECIALIZATION" "$CHECKED_COURSES" "$CHECKED_EXAMPLES" "$CHECKED_READMES"

    [ "$CHECKED_SPECIALIZATION" -eq 1 ] || bad "anti-vacuity" "no specialization was checked"
    [ "$CHECKED_COURSES" -ge 1 ]        || bad "anti-vacuity" "no course.toml was checked"
    [ "$CHECKED_EXAMPLES" -ge 1 ]       || bad "anti-vacuity" "no example.toml was checked"
    [ "$CHECKED_READMES" -ge 3 ]        || bad "anti-vacuity" "only $CHECKED_READMES README(s) checked; expected at least 3"

    all=$(mktemp)
    find "$root" -name .git -prune -o -type f -name 'README.md' -print | sort > "$all"
    sort -u -o "$OWNED_READMES" "$OWNED_READMES"
    unowned=$(comm -13 "$OWNED_READMES" "$all")
    if [ -n "$unowned" ]; then
        bad "anti-vacuity" "README(s) no TOML in this repo claims, so nothing above checked them: $(printf '%s' "$unowned" | sed "s|^$root/||" | tr '\n' ' ')"
    fi

    printf '\n'
    if [ "$PROBLEMS" -eq 0 ]; then
        printf 'OK — every checked README agrees with the TOML it was generated from.\n'
        printf 'NOTE: a consistency check, not a regenerate-and-diff. Prose reworded\n'
        printf '      inside a field, in the TOML and the README alike, agrees with\n'
        printf '      itself and is invisible here.\n'
        return 0
    fi
    printf '%d problem(s).\n' "$PROBLEMS"
    return 1
}

# ---------------------------------------------------------------------------
# --self-test: watch this script fail.
#
# A gate is worth the number of times someone has seen it go red. Each arm
# hand-edits a THROWAWAY COPY of the tree the way a person would, and asserts
# this script catches it. Arm 0 is the control: without it, every other arm is
# satisfied by a script that fails on everything.
# ---------------------------------------------------------------------------
selftest_pass=0
selftest_fail=0

st_ok()  { printf '  ok    %-32s %s\n' "$1" "$2"; selftest_pass=$((selftest_pass + 1)); }
st_bad() { printf '  FAIL  %-32s %s\n' "$1" "$2"; selftest_fail=$((selftest_fail + 1)); }

st_arm() { # name copy_dir expect_fail want_substring
    local name=$1 d=$2 expect=$3 want=$4 out rc
    set +e
    out=$("$SELF" "$d" 2>&1); rc=$?
    set -e
    if [ "$expect" = "yes" ]; then
        if [ "$rc" -eq 0 ]; then
            st_bad "$name" "checker PASSED a tree it should have rejected"
        elif printf '%s' "$out" | grep -Fq -- "$want"; then
            st_ok "$name" "caught: $(printf '%s' "$out" | grep -F -A1 -- "$want" | head -2 | tr '\n' ' ' | sed 's/  */ /g; s/^ //; s/ $//')"
        else
            st_bad "$name" "failed, but never said [$want]"
            printf '%s\n' "$out" | sed 's/^/        | /'
        fi
    elif [ "$rc" -eq 0 ]; then
        st_ok "$name" "clean tree passes"
    else
        st_bad "$name" "checker REJECTED the unmodified tree"
        printf '%s\n' "$out" | sed 's/^/        | /'
    fi
}

self_test() {
    local root=$1 d crm erm ct et long
    # Deliberately global: the EXIT trap fires after this function has returned
    # and its locals are gone.
    SELFTEST_T=$(mktemp -d)
    trap 'rm -rf "${SELFTEST_T:?}"' EXIT

    mkcopy() {
        local n=$1
        rm -rf "${SELFTEST_T:?}/$n"
        cp -a "$root" "$SELFTEST_T/$n"
        rm -rf "${SELFTEST_T:?}/$n/.git"
        printf '%s\n' "$SELFTEST_T/$n"
    }

    printf 'self-test — each arm hand-edits a copy of the tree and must be caught\n\n'

    # 0. Control. An unmodified copy must PASS, or every arm below is vacuous.
    d=$(mkcopy control)
    st_arm "control (unmodified)" "$d" no ""

    # A. A reworded H1 — the commonest hand-edit there is.
    d=$(mkcopy h1)
    sed -i '0,/^# /s/^# \(.*\)$/# \1 Reworded/' "$d/README.md"
    st_arm "H1 reworded" "$d" yes "H1 —"

    # B. A table row dropped from a course README.
    d=$(mkcopy row)
    crm=$(find "$d/courses" -mindepth 2 -maxdepth 2 -name README.md | head -1)
    sed -i "$(awk '/^\|/ { n = NR } END { print n }' "$crm")d" "$crm"
    st_arm "table row dropped" "$d" yes "rows, course.toml has"

    # C. The generated footer deleted.
    d=$(mkcopy footer)
    erm=$(find "$d/courses" -path '*/examples/*' -name README.md | head -1)
    sed -i '/^<sub>Generated/d' "$erm"
    st_arm "footer deleted" "$d" yes "generated-footer line is missing or wrong"

    # D. A link repointed at somewhere that is not there.
    d=$(mkcopy link)
    sed -i 's|](courses/|](courses/not-a-real-|' "$d/README.md"
    st_arm "link target broken" "$d" yes "does not exist on disk"

    # E. A field pushed past its length cap.
    d=$(mkcopy cap)
    ct=$(find "$d/courses" -mindepth 2 -maxdepth 2 -name course.toml | head -1)
    long=$(head -c 200 /dev/zero | tr '\0' 'x')
    sed -i "s|^tagline .*|tagline = \"$long\"|" "$ct"
    st_arm "length cap blown" "$d" yes "over this script's cap"

    # F. The course image deleted, the <img> left behind.
    d=$(mkcopy img)
    find "$d/courses" -name course-image.png -delete
    st_arm "image gone, <img> stays" "$d" yes "but assets/course-image.png is not on disk"

    # G. TOML this script cannot parse must be REFUSED, not mis-read. Without
    #    this arm the flattener could silently return the wrong value and every
    #    comparison above would be against nothing.
    d=$(mkcopy shape)
    et=$(find "$d/courses" -path '*/examples/*' -name example.toml | head -1)
    sed -i 's|^description .*|description = """|' "$et"
    st_arm "TOML shape not supported" "$d" yes "unsupported TOML at"

    # H. Anti-vacuity: a README no TOML claims. Nothing above would look at it,
    #    so it must not be quietly counted as fine.
    d=$(mkcopy orphan)
    printf '# Stray\n' > "$d/courses/README.md"
    st_arm "unclaimed README" "$d" yes "no TOML in this repo claims"

    # I. Anti-vacuity: nothing to check at all must FAIL, never pass quietly.
    #    This is the failure mode the whole script exists to avoid.
    d=$(mkcopy vacuous)
    find "$d" -name '*.toml' -delete
    st_arm "nothing to check" "$d" yes "anti-vacuity"

    printf '\nself-test: %d ok, %d failed\n' "$selftest_pass" "$selftest_fail"
    [ "$selftest_fail" -eq 0 ]
}

# ---------------------------------------------------------------------------
SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
DEFAULT_ROOT="$(cd "$(dirname "$SELF")/../.." && pwd)"

case "${1:-}" in
    --self-test) self_test "$(cd "${2:-$DEFAULT_ROOT}" && pwd)" ;;
    --help|-h)   sed -n '2,60p' "$SELF" ;;
    *)           run_checks "$(cd "${1:-$DEFAULT_ROOT}" && pwd)" ;;
esac
