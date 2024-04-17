#!/usr/bin/env -S sh -ex

sfdisk ${1:-/dev/nvme0n1} << EOF
label: gpt

start=,size= 120M, type=U, name=boot
start=,size= 931.5G, type=L, name=jozbox
start=,size= +, type=L, name=root
EOF

# TODO If using an SSD, should check for firmware upgrades

while ! ls /dev/disk/by-partlabel/root
	do sleep 0.1
done

mkfs.xfs -f /dev/disk/by-partlabel/jozbox
mkfs.xfs -f /dev/disk/by-partlabel/root
mkdir -p /mnt/gentoo
mount /dev/disk/by-partlabel/root /mnt/gentoo

mkfs.vfat -F 32 /dev/disk/by-partlabel/boot
mkdir /mnt/gentoo/boot
mount /dev/disk/by-partlabel/boot /mnt/gentoo/boot


