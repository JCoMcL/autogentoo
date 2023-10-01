DISK_SIZE = 8G
MEM = 2G
ARCH = x86_64
ISO_URL = https://distfiles.gentoo.org/releases/amd64/autobuilds/20230716T164653Z/install-amd64-minimal-20230716T164653Z.iso
HOST_SSH_PORT = 60022
INITIAL_PASSWD = root

QEMU_CMD = qemu-system-${ARCH} -m ${MEM} -cdrom boot.iso -nic user,hostfwd=tcp::${HOST_SSH_PORT}-:22 -monitor unix:qemu.sock,server,nowait

%/:
	mkdir -p $@

blank.raw:
	qemu-img create -f raw $@ ${DISK_SIZE}

img1.cow: blank.raw
	qemu-img create -o backing_file=$<,backing_fmt=raw -f qcow2 $@

boot.iso:
	wget ${ISO_URL} -O $@

ssh-wrapper/ssh: | ssh-wrapper/
	echo -e "#!/usr/bin/env sh\nsshpass -p ${INITIAL_PASSWD} $$(which ssh) -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" '$$@' > $@
	chmod +x $@

sendkeys.rb:
	curl https://raw.githubusercontent.com/mvidner/sendkeys/master/sendkeys | install -m 644 /dev/stdin sendkey.rb

stages/00-sshd: ssh-wrapper/ssh boot.iso sendkeys.rb | img1.cow stages/
	${MAKE} not-currently-running || ${MAKE} stop
	${QEMU_CMD} -boot order=d -drive file=img1.cow,format=qcow2 &
	echo #Once the system has booted and is in an interactive state, press ENTER to continue
	read
	./sendkeys.rb 'passwd<ret><delay>${INITIAL_PASSWD}<ret>${INITIAL_PASSWD}<ret><delay>rc-service sshd start<ret>' | socat - ./qemu.sock
	while ! $< -p ${HOST_SSH_PORT} root@127.0.0.1 true; do sleep 3; done
	# save and create the save flag. TODO abstract this out
	echo savevm 00-sshd | socat - ./qemu.sock
	touch $@

	${MAKE} stop

stages/%: | stages/ qemu.sock
	echo savevm $(@F) | socat - ./qemu.sock
	touch $@

not-currently-running:
	! ${MAKE} currently-running

currently-running:
	test -S qemu.sock
	pgrep qemu

resume-%: stages/%
	${MAKE} currently-running && \
	echo loadvm $* | socat - ./qemu.sock || \
	${QEMU_CMD} -nographic img1.cow -loadvm $* &
	sleep 3 #FIXME

resume: not-currently-running | stages/00-sshd
	${MAKE} resume-`ls stages | tail -n 1`

stop: currently-running
	echo quit | socat - ./qemu.sock || \
	( test "`pgrep qemu | wc -l`" -eq 1 && kill `pgrep qemu` )

ssh/key: | ssh/
	ssh-keygen -t ed25519 -qN '' -f $@
ssh/key.pub: ssh/key

stages/01-ssh-key: ssh/key.pub ssh-wrapper/ssh resume-00-sshd
	env PATH="ssh-wrapper:$$PATH" ssh-copy-id -i $< -p ${HOST_SSH_PORT} root@127.0.0.1
	# save and create the save flag. TODO abstract this out
	echo savevm $(@F) | socat - ./qemu.sock
	touch $@

#ANSIBLE SECTION

ansible/host: ssh/key
	echo "127.0.0.1:${HOST_SSH_PORT} ansible_user=root ansible_ssh_private_key_file=../$<" > $@

clean:
	rm -rf blank.raw img1.cow stages ssh ssh-wrapper ansible/host sendkeys.rb #boot.iso

.PHONY: resume resume-% stop clean reset currently-running not-currently-running
