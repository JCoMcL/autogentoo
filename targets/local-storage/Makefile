# _                    _   ____  _
#| |    ___   ___ __ _| | / ___|| |_ ___  _ __ __ _  __ _  ___
#| |   / _ \ / __/ _` | | \___ \| __/ _ \| '__/ _` |/ _` |/ _ \
#| |__| (_) | (_| (_| | |  ___) | || (_) | | | (_| | (_| |  __/
#|_____\___/ \___\__,_|_| |____/ \__\___/|_|  \__,_|\__, |\___|
#                                                   |___/

include options.mk
include ../common.mk

#TODO setting up localhost ssh should be delegated to something else e.g. `self` makefile
#export PATH := ssh-wrapper/ssh:$(PATH)
# remember that 'local-storage" and 'localhost' are not the same thing

checkpoints/01-linux-machine: checkpoints/
	touch $@
checkpoints/02-keyboard-access: checkpoints/01-linux-machine
	touch $@
checkpoints/03-ssh: checkpoints/02-keyboard-access
	touch $@

checkpoints/04-passwordless-ssh: checkpoints/03-ssh
	ssh localhost true || \
		exit 1 # can't ssh to localhost, you can likely fix this with the following command: `ssh-copy-id localhost`
	touch $@
checkpoints/05-disk-access: checkpoints/04-passwordless-ssh
	if [ -$(disk)

clean:
	rm -rf ssh ssh-wrapper options.mk

