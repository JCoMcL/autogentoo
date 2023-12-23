#!/usr/bin/env -S sh -e

#there is some failure of logic at play here:
#if you don't have a faster internet connection than the mirrors, the results will essentially be random
#in such a case, we should choose either the nearest (lowest latency) mirrors, or the most generally reliable
#ideally a mix of these two strategies
mirrorselect -os 6 >> /mnt/gentoo/etc/portage/make.conf
