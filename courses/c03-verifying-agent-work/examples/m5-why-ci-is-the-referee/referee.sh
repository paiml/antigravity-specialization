#!/bin/bash
# Independent clean-room CI referee.
# Copies only declared manifest files into a fresh temp directory and fails
# if any declared artifact is missing/empty, if check.sh fails syntax, or if
# checks are skipped/vacuous.

set -euo pipefail

usage() {
    echo "Usage: $0 <submission-dir> | --self-test" >&2
    exit 2
}

run_referee() {
    local src_dir="$1"
    local clean_dir
    local file_count=0
    local pass_count=0
    local line out ec

    [ -d "$src_dir" ] || { echo "FAIL: submission directory not found: $src_dir" >&2; return 1; }
    [ -s "$src_dir/manifest.txt" ] || { echo "FAIL: missing or empty manifest.txt in $src_dir" >&2; return 1; }

    clean_dir="$(mktemp -d)"

    while IFS= read -r line || [ -n "$line" ]; do
        [ -z "$line" ] && continue
        case "$line" in
            \#*) continue ;;
            *../*|/*)
                echo "FAIL: unsafe path in manifest.txt: $line" >&2
                rm -rf "$clean_dir"
                return 1
                ;;
        esac
        if [ ! -f "$src_dir/$line" ]; then
            echo "FAIL: declared artifact missing: $line" >&2
            rm -rf "$clean_dir"
            return 1
        fi
        if [ ! -s "$src_dir/$line" ]; then
            echo "FAIL: declared artifact is empty (0 bytes): $line" >&2
            rm -rf "$clean_dir"
            return 1
        fi
        mkdir -p "$clean_dir/$(dirname "$line")"
        cp "$src_dir/$line" "$clean_dir/$line"
        file_count=$((file_count + 1))
    done < "$src_dir/manifest.txt"

    if [ "$file_count" -eq 0 ]; then
        echo "FAIL: anti-vacuity: manifest.txt listed 0 files" >&2
        rm -rf "$clean_dir"
        return 1
    fi

    if [ ! -f "$clean_dir/check.sh" ]; then
        echo "FAIL: check.sh must be declared in manifest.txt" >&2
        rm -rf "$clean_dir"
        return 1
    fi

    if ! bash -n "$clean_dir/check.sh"; then
        echo "FAIL: syntax error in check.sh" >&2
        rm -rf "$clean_dir"
        return 1
    fi

    if grep -qE '(^|[[:space:]])(SKIP|TODO|FIXME)([[:space:]:]|$)' "$clean_dir/check.sh"; then
        echo "FAIL: check.sh contains skipped or unfinished check markers" >&2
        rm -rf "$clean_dir"
        return 1
    fi

    set +e
    out="$(cd "$clean_dir" && bash ./check.sh 2>&1)"
    ec=$?
    set -e

    if [ "$ec" -ne 0 ]; then
        echo "FAIL: check.sh exited $ec" >&2
        printf '%s\n' "$out" >&2
        rm -rf "$clean_dir"
        return 1
    fi

    pass_count="$(printf '%s\n' "$out" | awk '/^PASS:/{c++} END{print c+0}')"
    if [ "$pass_count" -eq 0 ]; then
        echo "FAIL: anti-vacuity: check.sh reported 0 PASS assertions" >&2
        rm -rf "$clean_dir"
        return 1
    fi

    rm -rf "$clean_dir"
    echo "REFEREE PASS: $src_dir ($file_count files verified, $pass_count assertion(s))"
    return 0
}

self_test() {
    local tmp
    tmp="$(mktemp -d)"

    mkdir -p "$tmp/empty"
    if run_referee "$tmp/empty" >/dev/null 2>&1; then
        echo "SELF-TEST FAIL: empty directory was accepted" >&2
        rm -rf "$tmp"
        return 1
    fi

    mkdir -p "$tmp/vacuous"
    printf 'check.sh\n' > "$tmp/vacuous/manifest.txt"
    printf '#!/bin/bash\necho "all good"\n' > "$tmp/vacuous/check.sh"
    if run_referee "$tmp/vacuous" >/dev/null 2>&1; then
        echo "SELF-TEST FAIL: vacuous check.sh without PASS assertion was accepted" >&2
        rm -rf "$tmp"
        return 1
    fi

    rm -rf "$tmp"
    echo "SELF-TEST OK"
    return 0
}

[ $# -eq 1 ] || usage
if [ "$1" = "--self-test" ]; then
    self_test
else
    run_referee "$1"
fi
