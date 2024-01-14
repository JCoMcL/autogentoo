#!/usr/bin/env -S arch-chroot /mnt/gentoo /usr/bin/env sh

mkdir /efi
mount /dev/disk/by-partlabel/boot /efi

emerge-webrsync

#skip eselect profile because the default is what we want for now

#this is important so that it doesn't take 1000 years to compile on VM
cat << EOF > /etc/portage/binrepos.conf/gentoobinhost.conf
[binhost]
priority = 9999
sync-uri = https://mirror.bytemark.co.uk/gentoo/releases/amd64/binpackages/17.1/x86-64/
EOF

cat << EOF >> /etc/portage/make.conf
# Appending getbinpkg to the list of values within the FEATURES variable
FEATURES="${FEATURES} getbinpkg"
# Require signatures
FEATURES="${FEATURES} binpkg-request-signature"
EOF

cat << EOF >> /etc/portage/make.conf
ACCEPT_LICENSE="@FREE @BINARY-REDISTRIBUTABLE"
EOF

emerge sys-kernel/linux-firmware

emerge sys-kernel/gentoo-kernel-bin
emerge --depclean

#The following borders on configuration and as such will be moved elsewhere once configuration is in scope for this project
genfstab -L / | sed s/relatime/noatime/ > /etc/fstab
echo autogentoo > /etc/hostname

emerge --ask net-misc/dhcpcd
rc-update add dhcpcd default
rc-service dhcpcd start
