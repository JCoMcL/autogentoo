#!/usr/bin/env sh

snapshot="`basename $0`"
dir="`dirname $0`"

echo "$snapshot is a fake checkpoint and it does nothing :)"

if [[ "$1" = '-p' ]]; then
	previous_snapshot="$(ls `dirname $0` | sed -n "/^$snapshot$/{x;p;q}; x")"
	previous_snapshot_path="`dirname $0`/$previous_snapshot"
	test -f "$previous_snapshot_path" && "$previous_snapshot_path"
else
	echo "run with -p to load a prior snapshot"
fi
