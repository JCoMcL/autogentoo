#!/usr/bin/env sh

#set -x

die() {
    echo "$@" >&2; exit 1
}

test -n "$1" || die "at least one argument (a URL) required"
URL="$1"

filter() {
    if [[ -n "$@" ]]; then
        sed -nE "/$(printf '|%s$' $@ | cut -c 2-)/p"
    else
        cat
    fi

}

shift
lynx -listonly -nonumbers -dump "$URL" | filter "$@" | wget -Ni /dev/stdin
