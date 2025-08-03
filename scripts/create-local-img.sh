#!/usr/bin/env sh

set -e

usage() {
    echo "Usage: $0 <image-file> <size>"
    echo "Example: $0 local.img 10G"
    echo "Size can be specified in K, M, G, T (e.g., 512M, 1G, 2T)"
    exit 1
}

if [ $# -ne 2 ]; then
    usage
fi

to_mib() {
    input="$1"
    # Convert common shorthands to IEC units for 'units'
    case "$input" in
        *K)   input="${input%K}KiB" ;;
        *M)   input="${input%M}MiB" ;;
        *G)   input="${input%G}GiB" ;;
        *T)   input="${input%T}TiB" ;;
    esac

    if ! command -v units >/dev/null 2>&1; then
        echo "Error: 'units' command not found. Please install GNU units." >&2
        exit 2
    fi

    units --one-line --compact "$input" MiB | awk '{print int($1)}'
}

IMG_FILE="$1"

SIZE_MIB=$(to_mib "$2")
set -x
dd if=/dev/zero of="$IMG_FILE" iflag=fullblock bs=1M count="$SIZE_MIB" status=progress
sync
