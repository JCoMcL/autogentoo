#!/usr/bin/env -S sh -e


error() {
	echo [0m[31m$@[0m >&2
}

warn() {
	echo "$@" >&2
}

die() {
	error $@
	exit 1
}

get_partition() {
	label="$1"
	lsblk -nr -o PATH,PARTLABEL "$DISK" |
		awk -v l="$label" '$2 == l { print $1; exit }'
}

tests() {
	set +e
	echo "trying get_part_via_appending_number with nvmen0"
	DISK=/dev/nvme0n1 get_part_via_appending_number root
	echo "trying get_part_via_appending_number with sdb"
	DISK=/dev/sdb get_part_via_appending_number boot
	echo "trying get_part_via_appending_number with no disk"
	get_part_via_appending_number boot
	echo "trying get_part_via_partlabel with disk that might exist"
	get_part_via_partlabel boot
	echo "trying get_part_via_partlabel with disk that doesn't exist (should take 2-4 seconds)"
	DISK=/dev/sdb get_part_via_partlabel a-partition-with-a-silly-name
	echo "trying default method"
	$get_partition boot

	exit 0
}

delay() {
	echo [1mproceeding with format in:
	seq 8 -1 1 | while read n; do echo -n "$n "; sleep 1; done
	echo [0m
}

ESP_SIZE="240"
while [ $# -gt 0 ]; do
	case "$1" in
		-h|--headless)
			delay(){ :; }
			DISK_SELECT_ARGS="$1"
			shift
			;;
		-b|--boot-size)
			shift
			set -u; ESP_SIZE=$1; set +u
			test $ESP_SIZE -gt 0 || die "--boot-size invalid argument: $1. Must be positive integer."
			shift
			;;
		-n|--no-boot)
			ESP_SIZE=
			shift
			;;
		--)
			shift
			break
			;;
		*)
			break
			;;
	esac
done

# TODO filter out duplicates
USER_DISK="${1:-$(disk-select.sh $DISK_SELECT_ARGS)}"
DISK=$(readlink -f "$USER_DISK") || die "Could not find disk: $USER_DISK"
test -b "$DISK" || die "$DISK not a block device"

#I don't suppose any of you guys know a way to do ansi escape codes that isn't annoying to read and to write
echo [1mselected disk is [0m[34m[1m$DISK[0m[1m$(readlink "$DISK">/dev/null && echo , a.k.a. [0m[34m[1m$(readlink -e $DISK))[0m
delay

set -x
lsblk -nr -o PATH,MOUNTPOINTS "$DISK" |
while read dev mps; do
	[ -z "$mps" ] && continue

	for mp in $mps; do
		case "$mp" in
			/|/boot|/efi|/usr|/var|/home)
				die "Refusing to unmount critical mountpoint: $mp"
				;;
		esac

		warn "Unmounting $mp"
		umount "$mp"
	done
done

wipefs --all "$DISK"
sfdisk "$DISK" << EOF
label: gpt

${ESP_SIZE:+"start=,size= ${ESP_SIZE}M, type=U, name=boot"}
start=,size= +, type=L, name=root
EOF

# TODO If using an SSD, should check for firmware upgrades

mkfs.f2fs -f "`get_partition root`"
mkdir -p /mnt/gentoo
mount "`get_partition root`" /mnt/gentoo

if test -n "$ESP_SIZE"
	then mkfs.vfat -F 32 "`get_partition boot`"
	mkdir -p /mnt/gentoo/efi
	mount "`get_partition boot`" /mnt/gentoo/efi
fi

