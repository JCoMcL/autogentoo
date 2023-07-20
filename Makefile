DISK_SIZE = 4G
MEM = 1G
ARCH = x86_64
ISO = install-amd64-minimal-20230625T165009Z.iso
HOST_SSH_PORT = 60022

QEMU_CMD = qemu-system-${ARCH} -m ${MEM} -nic user,hostfwd=tcp::${HOST_SSH_PORT}-:22

blank.raw:
	qemu-img create -f raw $@ ${DISK_SIZE}

img1.cow: blank.raw
	qemu-img create -o backing_file=$<,backing_fmt=raw -f qcow2 $@

${ISO}:
	wget https://mirror.init7.net/gentoo//releases/amd64/autobuilds/20230625T165009Z/$@ #obviously not a proper abstraction, just for the sake of brevity

setup: img1.cow ${ISO}
	echo "Press CTRL+Alt+2 and type 'savevm boot' once the system has booted and SSH is working"
	${QEMU_CMD} -cdrom ${ISO}  -boot order=d -drive file=$<,format=qcow2

resume: img1.cow
	${QEMU_CMD} -cdrom ${ISO} $< -loadvm boot

not-currently-running:
	! ls qemu.sock

currently-running:
	ls qemu.sock

resume-background: not-currently-running | img1.cow
	${QEMU_CMD} -cdrom ${ISO} -nographic -monitor unix:qemu.sock,server,nowait $| -loadvm boot &

stop: qemu.sock
	echo quit | socat - ./$<

%/:
	mkdir -p $@
ssh/key: ssh/
	ssh-keygen -t ed25519 -qN '' -f $@
ssh/key.pub: ssh/key
copy-id: ssh/key.pub
	ssh-copy-id -i $< -p ${HOST_SSH_PORT} root@127.0.0.1 ansible #TODO patch in sshpass to remove password prompt

#ANSIBLE SECTION

ansible/host: ssh/key
	echo "127.0.0.1:${HOST_SSH_PORT} ansible_user=root ansible_ssh_private_key_file=../$<" > $@

clean:
	rm -rf blank.raw img1.cow ssh ansible/host

.PHONY: setup resume resume-background stop clean reset currently-running not-currently-running
