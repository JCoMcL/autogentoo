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

stages/00-sshd: img1.cow boot.iso not-currently-running stages/
	${QEMU_CMD} -boot order=d -drive file=$<,format=qcow2 &
	echo #Once the system has booted and is in an interactive state, press ENTER to continue
	read
	./sendkeys.rb 'passwd<ret><delay>${INITIAL_PASSWD}<ret>${INITIAL_PASSWD}<ret><delay>rc-service sshd start<ret>' | socat - ./qemu.sock
	while ! sshpass -p ${INITIAL_PASSWD} ssh -o 'UserKnownHostsFile=/dev/null' -o StrictHostKeyChecking=no -p ${HOST_SSH_PORT} root@127.0.0.1 true; do sleep 3; done
	# save and create the save flag. TODO abstract this out
	echo savevm 00-sshd | socat - ./qemu.sock
	echo quit' | socat - ./qemu.sock
	touch $@

resume: img1.cow
	${QEMU_CMD} $< -loadvm boot

not-currently-running:
	! ls qemu.sock

currently-running:
	ls qemu.sock

resume-background: not-currently-running | img1.cow
	${QEMU_CMD} -nographic $| -loadvm boot &

stop: qemu.sock
	echo quit | socat - ./$<

ssh/key: ssh/
	ssh-keygen -t ed25519 -qN '' -f $@
ssh/key.pub: ssh/key
copy-id: ssh/key.pub
	echo "type ${INITIAL_PASSWD}
	ssh-copy-id -i $< -p ${HOST_SSH_PORT} root@127.0.0.1 #TODO patch in sshpass to remove password prompt

#ANSIBLE SECTION

ansible/host: ssh/key
	echo "127.0.0.1:${HOST_SSH_PORT} ansible_user=root ansible_ssh_private_key_file=../$<" > $@

clean:
	rm -rf blank.raw img1.cow stages ssh ansible/host #boot.iso

.PHONY: resume resume-background stop clean reset currently-running not-currently-running
