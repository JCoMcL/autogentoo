#!/usr/bin/env sh

snapshot="`basename $0`"
while [[ -n "$1" ]]; do
	case "$1" in
		-p) true;;
		-*) echo "unrecognized option: $1" 1>&2 && exit 1;;
		*) snapshot="`basename $1`";;
	esac
	shift
done
scripts/qemu-cmd.sh loadvm $snapshot
