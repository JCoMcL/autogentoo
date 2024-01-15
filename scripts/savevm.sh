#!/usr/bin/env sh

set -x

scripts/qemu-cmd.sh savevm $1
while ! scripts/qemu-cmd.sh info snapshots | grep $1; do sleep 3; done
install -m 555 scripts/loadvm.sh "stages/`basename $1`"
