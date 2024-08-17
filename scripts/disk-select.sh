#!/usr/bin/env -S sh -e

find /dev/disk/by-id -not -name '*-part*' -not -type d | umenu -d "Select the disk to format"
