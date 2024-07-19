#!/usr/bin/env -S sh -e

DISK="$1"
# TODO filter out duplicates
DISK="${DISK:=$(find /dev/disk/by-id -not -name '*-part*' -not -type d | umenu -d "Select the disk to format")}"

#I don't suppose any of you guys know a way to do ansi escape codes that isn't annoying to read and to write
echo [1mselected disk is [0m[34m[1m$DISK[0m[1m$(readlink "$DISK">/dev/null && echo , a.k.a. [0m[34m[1m$(readlink -e $DISK))[0m
echo [1mproceeding with format in:
seq 8 -1 1 | while read n; do echo -n "$n "; sleep 1; done
echo [0m

sfdisk "$DISK" << EOF
label: gpt

start=,size= 120M, type=U, name=boot
start=,size=  +, type=L, name=root
EOF

# TODO If using an SSD, should check for firmware upgrades

# FIXME partlabel is ambiguous if we're running from a system that already has disks with these partlabels
# realistically, there may not be any good, safe way to refer to a partition we just created in shell script
exit 1
while ! ls /dev/disk/by-partlabel/boot
	do sleep 0.1
done

mkfs.vfat -F 32 /dev/disk/by-partlabel/boot
mkfs.xfs /dev/disk/by-partlabel/root

mkdir -p /mnt/gentoo
mount /dev/disk/by-partlabel/root /mnt/gentoo

