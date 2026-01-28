# _                    _   ____  _
#| |    ___   ___ __ _| | / ___|| |_ ___  _ __ __ _  __ _  ___
#| |   / _ \ / __/ _` | | \___ \| __/ _ \| '__/ _` |/ _` |/ _ \
#| |__| (_) | (_| (_| | |  ___) | || (_) | | | (_| | (_| |  __/
#|_____\___/ \___\__,_|_| |____/ \__\___/|_|  \__,_|\__, |\___|
#                                                   |___/

include ../../options.mk
include ../common.mk

#TODO setting up localhost ssh should be delegated to something else e.g. `self` makefile
#export PATH := ssh-wrapper/ssh:$(PATH)
# remember that 'local-storage" and 'localhost' are not the same thing

checkpoints/01-linux-machine: checkpoints/
	touch $@
checkpoints/02-keyboard-access: checkpoints/01-linux-machine
	touch $@
checkpoints/03-ssh: checkpoints/02-keyboard-access
	ln -sf `which ssh` $@

checkpoints/04-passwordless-ssh: checkpoints/03-ssh
	ssh -o BatchMode=yes localhost true || \
		exit 1 # can't ssh to localhost, you can likely fix this with the following command: `ssh-copy-id localhost`
	ln -sf $< $@

local.img:
	create-local-img.sh $@ $(VIRTUAL_DISK_SIZE)

/dev/loop0: local.img
	losetup --find --show --partscan $< #FIXME: this asumes there isn't an exisitng loop device

checkpoints/05-disk-access: checkpoints/04-passwordless-ssh
	disk_choice="`select-disk.sh --try-first "$(disk)" --additional-options "/dev/loop0 (local virtual disk)"`" && \
	if [ "$$disk_choice" = /dev/loop0 ]; then $(MAKE) /dev/loop0; fi && \
	ln -sf "$$disk_choice" $@

clean:
	rm -rf ssh ssh-wrapper options.mk *.img checkpoints
	if mountpoint -q /mnt/gentoo; then umount -R /mnt/gentoo/; fi

