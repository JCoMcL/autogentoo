#!/usr/bin/env -S arch-chroot /mnt/gentoo /usr/bin/env sh

mkdir /efi
mount /dev/disk/by-partlabel/boot /efi

#emerge-webrsync
