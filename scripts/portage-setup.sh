#!/usr/bin/env -S sh -e

mkdir -p /mnt/gentoo/etc/protage/repos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf

#I'm intending to build a portable system, so this probably doesn't make much sense
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/

arch-chroot /mnt/gentoo.
mkdir /efi
mount /dev/disk/by-partlabel/boot
