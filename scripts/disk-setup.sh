#!/usr/bin/env sh

sfdisk /dev/sda << EOF
,1G,U
,+,L
EOF

