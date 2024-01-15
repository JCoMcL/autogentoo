#!/usr/bin/env sh

currently-running() { #TODO abstract this out
	test -S qemu.sock && pgrep qemu
}

echo $0
basename $0

#if currently-running; then
	#scripts/qemu-cmd.sh loadvm
