#!/usr/bin/env sh

snapshot="`basename $0`"
test -n "$1" && snapshot="`basename $1`"
scripts/qemu-cmd.sh loadvm $snapshot
