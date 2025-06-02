#!/usr/bin/env sh
err() {
	echo "Error: $(color red)$@$(color off)" >&2
}
warn() {
	echo "$(color blue)$@$(color off)" >&2
}
die() {
	err $@
	exit 1
}

append_line() {
cat - /dev/stderr 2<<EOF
$1
EOF
}

append_lines() {
	if test -z "$@"; then
		cat
	else
		for line in "$@"; do
			append_line $line
		done
	fi
}

_select_disk() {
	lsblk --filter 'TYPE == "disk"' --noheadings --output PATH,MODEL |
	append_lines $ADDITIONAL_OPTIONS |
	umenu -d "
No default disk provided in options.mk
Select a disk for install" |
	cut -f1 -d' '
}

while [ $# -gt 0 ]; do
	case "$1" in
		--try-first)
			shift
			test -n "$1" && eval "_select_disk() { echo $1; }"
			shift
			;;
		--additional-options)
			shift
			IFS=,
			set -u; ADDITIONAL_OPTIONS=$1; set +u
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

is_disk_mounted() {
	(lsblk -no MOUNTPOINT $1 | grep .) >/dev/null 2>/dev/null
}


DISK=$(_select_disk)
if is_disk_mounted $DISK; then
	die "$DISK is mounted. This is probably not what you want"
fi

echo $DISK

