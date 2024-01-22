#!/usr/bin/env sh

cd

cp -r /etc/ssh /mnt/gentoo/etc
cp -r /etc/shadow /mnt/gentoo/etc
cp -r /root/.ssh /mnt/gentoo/root/

exit 0

umount -l /mnt/gentoo/dev{/shm,/pts,}
umount -R /mnt/gentoo

reboot
