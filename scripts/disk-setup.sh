#!/usr/bin/env -S sh -e


#if ls /dev/disk/by-partlabel/boot; then

error() {
	echo [0m[31m$@[0m >&2
}

get_disk_via_appending_number() {
	# I wouldn't trust this if I were you
	if test -z "$DISK"; then
		error "DISK is not set"
		return 1
	fi
	disk="$(readlink -e $DISK)"

	label="$1"
	num=$(case "$label" in
		boot) echo -n 1 ;;
		root) echo -n 2 ;;
		*) error "$label not recognised as a partition name"; return 1
	esac)|| return 1
	pre=$(case $disk in
		/dev/nvme*) echo -n 'p' ;;
	esac)
	ls "$disk$pre$num"
}

get_disk_via_partlabel() {
	label="$1"
	for retry in `seq 0.1 0.1 1`; do
		ls "/dev/disk/by-partlabel/$label" 2>/dev/null && return
		sleep $retry
	done
	error "failed to get disk '$label' via partlabel, attempting other method"
	get_disk_via_appending_number "$label"
}

testcases() {
	set +e
	echo "trying get_disk_via_appending_number with nvmen0"
	DISK=/dev/nvme0n1 get_disk_via_appending_number root
	echo "trying get_disk_via_appending_number with sdb"
	DISK=/dev/sdb get_disk_via_appending_number boot
	echo "trying get_disk_via_partlabel with disk that might exist"
	get_disk_via_partlabel boot
	echo "trying get_disk_via_partlabel with disk that doesn't exist (should take 2-4 seconds)"
	DISK=/dev/sdb get_disk_via_partlabel a-partition-with-a-silly-name
	exit 0
}

testcases
exit 1

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


