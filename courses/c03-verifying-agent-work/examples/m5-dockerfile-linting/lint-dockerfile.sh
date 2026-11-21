#!/bin/bash
# Deterministic Dockerfile linter using bash and awk only.
# Enforces pinned base images, WORKDIR over RUN cd, COPY over ADD,
# package manager cache cleanup, and a non-root USER.

set -euo pipefail

usage() {
    echo "Usage: $0 <Dockerfile> | --self-test" >&2
    exit 2
}

lint_dockerfile() {
    local df="$1"
    [ -f "$df" ] || { echo "FAIL: Dockerfile not found: $df" >&2; return 1; }
    [ -s "$df" ] || { echo "FAIL: Dockerfile is empty: $df" >&2; return 1; }

    awk '
    function check_line(ln, instr,    upper, img, user_val) {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", instr)
        if (instr == "") return
        upper = toupper(instr)

        if (upper ~ /^FROM[[:space:]]+/) {
            from_count++
            img = instr
            sub(/^[Ff][Rr][Oo][Mm][[:space:]]+(--platform=[^[:space:]]+[[:space:]]+)?/, "", img)
            sub(/[[:space:]]+[Aa][Ss][[:space:]]+.*/, "", img)
            if (img !~ /:/ && img !~ /@sha256:[0-9a-f]{64}$/) {
                printf "FAIL line %d [DL3006]: unpinned FROM image \"%s\"\n", ln, img > "/dev/stderr"
                errors++
            } else if (img ~ /:latest$/) {
                printf "FAIL line %d [DL3007]: FROM uses :latest tag \"%s\"\n", ln, img > "/dev/stderr"
                errors++
            }
        }

        if (upper ~ /^RUN[[:space:]]+/ && instr ~ /(^|[;&|[:space:]])cd[[:space:]]+/) {
            printf "FAIL line %d [DL3003]: use WORKDIR instead of \"RUN cd ...\"\n", ln > "/dev/stderr"
            errors++
        }

        if (upper ~ /^ADD[[:space:]]+/ && upper !~ /^ADD[[:space:]]+HTTPS?:\/\//) {
            printf "FAIL line %d [DL3020]: use COPY instead of ADD for local files\n", ln > "/dev/stderr"
            errors++
        }

        if (upper ~ /^RUN[[:space:]]+/ && instr ~ /apt-get[[:space:]]+install/) {
            if (instr !~ /--no-install-recommends/) {
                printf "FAIL line %d [DL3015]: apt-get install missing --no-install-recommends\n", ln > "/dev/stderr"
                errors++
            }
            if (instr !~ /\/var\/lib\/apt\/lists\/\*/) {
                printf "FAIL line %d [DL3009]: apt-get install must clean /var/lib/apt/lists/*\n", ln > "/dev/stderr"
                errors++
            }
        }

        if (upper ~ /^RUN[[:space:]]+/ && instr ~ /apk[[:space:]]+add/ && instr !~ /--no-cache/) {
            printf "FAIL line %d [DL3018]: apk add missing --no-cache\n", ln > "/dev/stderr"
            errors++
        }

        if (upper ~ /^USER[[:space:]]+/) {
            user_val = instr
            sub(/^[Uu][Ss][Ee][Rr][[:space:]]+/, "", user_val)
            sub(/:.*/, "", user_val)
            last_user = user_val
        }
    }

    BEGIN { buf=""; start_line=1; from_count=0; errors=0; last_user="" }
    {
        raw = $0
        sub(/\r$/, "", raw)
        if (buf == "" && (raw ~ /^[[:space:]]*#/ || raw ~ /^[[:space:]]*$/)) next
        if (buf == "") start_line = NR
        if (raw ~ /\\[[:space:]]*$/) {
            sub(/\\[[:space:]]*$/, " ", raw)
            buf = buf raw
            next
        }
        full = buf raw
        buf = ""
        check_line(start_line, full)
    }
    END {
        if (buf != "") check_line(start_line, buf)
        if (from_count == 0) {
            print "FAIL [anti-vacuity]: no FROM instruction found" > "/dev/stderr"
            errors++
        }
        if (last_user == "" || last_user == "root" || last_user == "0") {
            print "FAIL [CIS-DI-0001]: container must switch to a non-root USER" > "/dev/stderr"
            errors++
        }
        if (errors > 0) {
            printf "LINT FAILED: %d violation(s) in %s\n", errors, FILENAME > "/dev/stderr"
            exit 1
        }
        printf "LINT PASS: %s (0 violations)\n", FILENAME
    }
    ' "$df"
}

self_test() {
    local tmp
    tmp="$(mktemp -d)"

    : > "$tmp/Dockerfile.empty"
    if lint_dockerfile "$tmp/Dockerfile.empty" >/dev/null 2>&1; then
        echo "SELF-TEST FAIL: empty Dockerfile accepted" >&2
        rm -rf "$tmp"
        return 1
    fi

    printf 'FROM alpine:latest\n' > "$tmp/Dockerfile.latest"
    if lint_dockerfile "$tmp/Dockerfile.latest" >/dev/null 2>&1; then
        echo "SELF-TEST FAIL: :latest tag accepted" >&2
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
    lint_dockerfile "$1"
fi
