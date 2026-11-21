#!/bin/bash
# Audits a repository's verification anatomy:
# 1. project.toml exists and all declared [[artifacts]] exist and are non-empty.
# 2. All scripts/*.sh pass bash -n and declare set -euo pipefail.
# 3. project.toml's verify command matches AGENTS.md and .github/workflows/ci.yml.
# 4. Running the verify command in a clean temp copy passes with >= 1 PASS line.

set -euo pipefail

usage() {
    echo "Usage: $0 <repo-dir> | --self-test" >&2
    exit 2
}

audit_repo() {
    local repo="$1"
    local verify_cmd artifact art_count=0 script_count=0 s clean_dir out ec pass_count unpinned

    [ -d "$repo" ] || { echo "FAIL: directory not found: $repo" >&2; return 1; }
    [ -s "$repo/project.toml" ] || { echo "FAIL: missing or empty project.toml" >&2; return 1; }
    [ -s "$repo/AGENTS.md" ] || { echo "FAIL: missing or empty AGENTS.md" >&2; return 1; }
    [ -s "$repo/.github/workflows/ci.yml" ] || { echo "FAIL: missing or empty .github/workflows/ci.yml" >&2; return 1; }

    verify_cmd="$(awk -F'"' '/^verify[[:space:]]*=/{print $2; exit}' "$repo/project.toml")"
    if [ -z "$verify_cmd" ]; then
        echo "FAIL: project.toml missing verify = \"...\"" >&2
        return 1
    fi

    while IFS= read -r artifact; do
        [ -z "$artifact" ] && continue
        if [ ! -s "$repo/$artifact" ]; then
            echo "FAIL: manifest artifact missing or empty: $artifact" >&2
            return 1
        fi
        art_count=$((art_count + 1))
    done < <(awk -F'"' '/^path[[:space:]]*=/{print $2}' "$repo/project.toml")

    if [ "$art_count" -eq 0 ]; then
        echo "FAIL: anti-vacuity: project.toml declares 0 artifacts" >&2
        return 1
    fi

    if ! grep -qF "$verify_cmd" "$repo/AGENTS.md"; then
        echo "FAIL: AGENTS.md does not document verify command: $verify_cmd" >&2
        return 1
    fi

    if ! grep -qF "$verify_cmd" "$repo/.github/workflows/ci.yml"; then
        echo "FAIL: CI workflow does not invoke verify command: $verify_cmd" >&2
        return 1
    fi

    unpinned="$(awk '/uses:/{ if ($0 !~ /@(v[0-9]+|[0-9a-f]{40})/) print NR ": " $0 }' "$repo/.github/workflows/ci.yml")"
    if [ -n "$unpinned" ]; then
        echo "FAIL: unpinned action in ci.yml: $unpinned" >&2
        return 1
    fi

    for s in "$repo"/scripts/*.sh; do
        [ -f "$s" ] || continue
        script_count=$((script_count + 1))
        bash -n "$s" || { echo "FAIL: syntax error in $s" >&2; return 1; }
        grep -q 'set -euo pipefail' "$s" || { echo "FAIL: $s missing set -euo pipefail" >&2; return 1; }
    done
    if [ "$script_count" -eq 0 ]; then
        echo "FAIL: anti-vacuity: no scripts/*.sh found" >&2
        return 1
    fi

    clean_dir="$(mktemp -d)"
    cp -r "$repo"/. "$clean_dir"/
    set +e
    out="$(cd "$clean_dir" && bash "$verify_cmd" 2>&1)"
    ec=$?
    set -e
    rm -rf "$clean_dir"

    if [ "$ec" -ne 0 ]; then
        echo "FAIL: clean-room verify command exited $ec" >&2
        printf '%s\n' "$out" >&2
        return 1
    fi

    pass_count="$(printf '%s\n' "$out" | awk '/^PASS:/{c++} END{print c+0}')"
    if [ "$pass_count" -eq 0 ]; then
        echo "FAIL: verify command reported 0 PASS assertions" >&2
        return 1
    fi

    echo "AUDIT PASS: $repo ($art_count artifacts, $script_count scripts, $pass_count assertions)"
    return 0
}

self_test() {
    local tmp
    tmp="$(mktemp -d)"
    mkdir -p "$tmp/empty"
    if audit_repo "$tmp/empty" >/dev/null 2>&1; then
        echo "SELF-TEST FAIL: empty directory accepted" >&2
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
    audit_repo "$1"
fi
