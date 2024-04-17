#!/usr/bin/env -S sh -e

mkdir -p /mnt/gentoo/etc/portage/repos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf

#I'm intending to build a portable system, so this probably doesn't make much sense
cp --dereference  /etc/resolv.conf /mnt/gentoo/etc/ || true as this sometimes fails when run again #TODO better error handling or maybe just remove this line


#there is some failure of logic at play here:
#if you don't have a faster internet connection than the mirrors, the results will essentially be random
#in such a case, we should choose either the nearest (lowest latency) mirrors, or the most generally reliable
#ideally a mix of these two strategies
mirrorselect -os 6 >> /mnt/gentoo/etc/portage/make.conf
