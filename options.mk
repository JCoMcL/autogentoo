ARCH=x86_64
GENTOO_ARCH = $(subst x86_64,amd64,$(ARCH))

INITIAL_PASSWD=roto

SSH_ADDRESS=localhost
SSH_PORT=
SSH_USER=root

#Generic settings for virtual machines and virtual disks
VIRTUAL_DISK_SIZE = 10G
VIRTUAL_MEM = 2G
