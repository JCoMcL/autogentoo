#!/usr/bin/env sh

#set -x

die() {
    echo "$@" >&2; exit 1
}

test -n "$1" || die "at least one argument (a URL) required"
URL="$1"

filter() {
    if [[ -n "$@" ]]; then
        sed -nE "/$(echo $@ |
            awk '{
                split($0,a," ")
                out=$1
                for (i=1;i<=length(a);i++)
                    out = out "$|" a[i]
                print out "$"
            }')/p"
            # yeah, I'm not so proud of this one
    else
        cat
    fi

}

shift
lynx -listonly -nonumbers -dump "$URL" | filter "$@" | wget -Ni /dev/stdin
