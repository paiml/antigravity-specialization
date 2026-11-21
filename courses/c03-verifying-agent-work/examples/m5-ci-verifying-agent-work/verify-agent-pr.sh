#!/bin/bash
# CI gate for verifying agent-submitted pull requests.
# Checks: scope boundary, syntax/strict mode, no TODOs/secrets, test integrity,
# and clean-room test execution.

set -euo pipefail

usage() {
    echo "Usage: $0 <pr-dir> | --self-test" >&2
    exit 2
}

verify_pr() {
    local pr_dir="$1"
    local clean_dir f prefix allowed changed_count=0 pass_count=0 test_out test_ec

    [ -d "$pr_dir" ] || { echo "FAIL: PR directory not found: $pr_dir" >&2; return 1; }
    [ -s "$pr_dir/allowed-paths.txt" ] || { echo "FAIL: missing or empty allowed-paths.txt" >&2; return 1; }
    [ -s "$pr_dir/changed-files.txt" ] || { echo "FAIL: missing or empty changed-files.txt" >&2; return 1; }

    clean_dir="$(mktemp -d)"

    while IFS= read -r f || [ -n "$f" ]; do
        [ -z "$f" ] && continue
        case "$f" in
            \#*) continue ;;
            *../*|/*)
                echo "FAIL: unsafe changed path: $f" >&2
                rm -rf "$clean_dir"
                return 1
                ;;
        esac

        allowed=0
        while IFS= read -r prefix || [ -n "$prefix" ]; do
            [ -z "$prefix" ] && continue
            case "$f" in
                "$prefix"*) allowed=1; break ;;
            esac
        done < "$pr_dir/allowed-paths.txt"

        if [ "$allowed" -ne 1 ]; then
            echo "FAIL [scope]: out-of-scope file modified by agent: $f" >&2
            rm -rf "$clean_dir"
            return 1
        fi

        if [ ! -s "$pr_dir/$f" ]; then
            echo "FAIL [artifact]: changed file missing or empty: $f" >&2
            rm -rf "$clean_dir"
            return 1
        fi

        mkdir -p "$clean_dir/$(dirname "$f")"
        cp "$pr_dir/$f" "$clean_dir/$f"
        changed_count=$((changed_count + 1))

        case "$f" in
            *.sh)
                if ! bash -n "$clean_dir/$f"; then
                    echo "FAIL [syntax]: bash -n failed on $f" >&2
                    rm -rf "$clean_dir"
                    return 1
                fi
                if ! grep -q 'set -euo pipefail' "$clean_dir/$f"; then
                    echo "FAIL [strict]: $f missing 'set -euo pipefail'" >&2
                    rm -rf "$clean_dir"
                    return 1
                fi
                if grep -qE '(TODO|FIXME|XXX)' "$clean_dir/$f"; then
                    echo "FAIL [hygiene]: $f contains TODO/FIXME/XXX marker" >&2
                    rm -rf "$clean_dir"
                    return 1
                fi
                if grep -qE '(/home/[A-Za-z0-9_-]+|/Users/[A-Za-z0-9_-]+|AIza[0-9A-Za-z_-]{10,}|sk-[0-9A-Za-z]{10,}|ghp_[0-9A-Za-z]{10,})' "$clean_dir/$f"; then
                    echo "FAIL [security]: $f contains hardcoded user path or secret pattern" >&2
                    rm -rf "$clean_dir"
                    return 1
                fi
                ;;
        esac
    done < "$pr_dir/changed-files.txt"

    if [ "$changed_count" -eq 0 ]; then
        echo "FAIL [anti-vacuity]: 0 changed files verified" >&2
        rm -rf "$clean_dir"
        return 1
    fi

    if [ ! -f "$clean_dir/tests/run_tests.sh" ]; then
        echo "FAIL [tests]: tests/run_tests.sh not present in PR" >&2
        rm -rf "$clean_dir"
        return 1
    fi

    if grep -qE '^[[:space:]]*#.*(PASS:|assert|expect)' "$clean_dir/tests/run_tests.sh"; then
        echo "FAIL [integrity]: commented-out test or assertion found in tests/run_tests.sh" >&2
        rm -rf "$clean_dir"
        return 1
    fi

    set +e
    test_out="$(cd "$clean_dir" && bash ./tests/run_tests.sh 2>&1)"
    test_ec=$?
    set -e

    if [ "$test_ec" -ne 0 ]; then
        echo "FAIL [tests]: tests/run_tests.sh exited $test_ec" >&2
        printf '%s\n' "$test_out" >&2
        rm -rf "$clean_dir"
        return 1
    fi

    pass_count="$(printf '%s\n' "$test_out" | awk '/^PASS:/{c++} END{print c+0}')"
    if [ "$pass_count" -lt 2 ]; then
        echo "FAIL [anti-vacuity]: expected >= 2 PASS assertions, got $pass_count" >&2
        rm -rf "$clean_dir"
        return 1
    fi

    rm -rf "$clean_dir"
    echo "AGENT PR PASS: $changed_count file(s) in scope, $pass_count assertion(s) passed"
    return 0
}

self_test() {
    local tmp
    tmp="$(mktemp -d)"

    mkdir -p "$tmp/empty"
    if verify_pr "$tmp/empty" >/dev/null 2>&1; then
        echo "SELF-TEST FAIL: empty PR directory accepted" >&2
        rm -rf "$tmp"
        return 1
    fi

    mkdir -p "$tmp/bad-scope/.github/workflows"
    printf 'src/\ntests/\n' > "$tmp/bad-scope/allowed-paths.txt"
    printf '.github/workflows/ci.yml\n' > "$tmp/bad-scope/changed-files.txt"
    printf 'name: hijack\n' > "$tmp/bad-scope/.github/workflows/ci.yml"
    if verify_pr "$tmp/bad-scope" >/dev/null 2>&1; then
        echo "SELF-TEST FAIL: out-of-scope edit accepted" >&2
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
    verify_pr "$1"
fi
