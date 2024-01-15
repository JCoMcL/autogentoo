#!/usr/bin/env sh

scripts/qemu-cmd.sh savevm $1
while ! scripts/qemu-cmd.sh info snapshots | grep $1; do sleep 3; done
touch stages/$1
