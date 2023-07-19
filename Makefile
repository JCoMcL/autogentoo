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

close-background: qemu.sock
	echo quit | socat - ./$<

clean:
	pgrep -F qemu_pid || rm -f qemu_pid

reset: clean
	rm -f blank.raw img1.cow img1.cow.boot

.PHONY: setup resume resume-background close-background clean reset currently-running not-currently-running
