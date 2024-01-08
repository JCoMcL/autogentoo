#!/usr/bin/env sh

 echo -e $@ | socat -Wqemu.lock - ./qemu.sock
