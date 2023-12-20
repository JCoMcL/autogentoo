#!/usr/bin/env -S sh -e

sfdisk /dev/sda << EOF
label: gpt

start=,size= 1G, type=U, name=boot
start=,size=  +, type=L, name=root
EOF

# TODO If using an SSD, should check for firmware upgrades

while ! ls /dev/disk/by-partlabel/boot
	do sleep 0.1
done

mkfs.vfat -F 32 /dev/disk/by-partlabel/boot
mkfs.xfs /dev/disk/by-partlabel/root

mkdir -p /mnt/gentoo
mount /dev/disk/by-partlabel/root /mnt/gentoo

