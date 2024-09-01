#  ___  _____ __  __ _   _   __  __       _         __ _ _
# / _ \| ____|  \/  | | | | |  \/  | __ _| | _____ / _(_) | ___
#| | | |  _| | |\/| | | | | | |\/| |/ _` | |/ / _ \ |_| | |/ _ \
#| |_| | |___| |  | | |_| | | |  | | (_| |   <  __/  _| | |  __/
# \__\_\_____|_|  |_|\___/  |_|  |_|\__,_|_|\_\___|_| |_|_|\___|

DISK_SIZE = 10G
MEM = 2G

SAVE_0 = scripts/fake-savevm.sh
SAVE_1 = scripts/savevm.sh

QEMU = qemu-system-${ARCH} -pidfile qemu.pid --enable-kvm -m ${MEM} -nic user,hostfwd=tcp::${HOST_SSH_PORT}-:22 -monitor unix:qemu.sock,server,nowait

include ../common.mk

include options.mk
#override defaults
SSH_PORT=60022

blank.raw:
	qemu-img create -f raw $@ ${DISK_SIZE}

img1.cow: blank.raw
	qemu-img create -o backing_file=$<,backing_fmt=raw -f qcow2 $@

sendkeys.rb:
	curl https://raw.githubusercontent.com/mvidner/sendkeys/master/sendkeys | install -m 555 /dev/stdin $@

boot.iso:
	scripts/download-files.sh https://distfiles.gentoo.org/releases/$(GENTOO_ARCH)/autobuilds/current-install-$(GENTOO_ARCH)-minimal iso
	mv *.iso $@

stages/00-interactive: boot.iso sendkeys.rb | img1.cow stages/
	${MAKE} not-currently-running || ${MAKE} stop
	${QEMU} -cdrom boot.iso -boot once=d -drive file=img1.cow,format=qcow2 &
	$(info "Once the system has booted and is in an interactive state, press ENTER to continue")
	read
	$(SAVE_1) $(@F) #FIXME logics breaks if this is a fake save

stages/01-sshd: stages/00-interactive sendkeys.rb
	${MAKE} resume-00-interactive
	./sendkeys.rb 'passwd<ret><delay>${INITIAL_PASSWD}<ret>${INITIAL_PASSWD}<ret><delay>rc-service sshd start<ret>' | socat - ./qemu.sock
	while ! sshpass -p ${INITIAL_PASSWD} root@127.0.0.1:${HOST_SSH_PORT} true; do sleep 3; done
	$(SAVE_0) $(@F)

not-currently-running:
	! ${MAKE} currently-running

currently-running:
	test -f qemu.pid && ps h -o cmd -p `<qemu.pid` | grep qemu
	#test -S qemu.sock

RESUME = $(patsubst stages/%,resume-%,$(wildcard stages/*))
$(RESUME): resume-%: stages/%
	if ${MAKE} currently-running ; then\
		$< ;\
	else\
		${QEMU} -cdrom boot.iso img1.cow -loadvm $* &;\
	fi
	sleep 3 #FIXME

resume: not-currently-running | stages/00-interactive
	${MAKE} resume-`ls stages | tail -n 1`

stop:
	if ${MAKE} currently-running; then\
		if ! timeout 5 scripts/qemu-cmd.sh quit; then\
			kill `<qemu.pid`;\
			rm -f qemu.pid ;\
		fi;\
	fi

%.fd:
	find /usr /nix -name $@ -exec cp {} . \; -print -quit | grep .

and-then-boot: stages/05-reboot OVMF_CODE.fd OVMF_VARS.fd
	${MAKE} stop
	${QEMU} img1.cow\
	  -machine q35,smm=on,accel=kvm \
	  -global driver=cfi.pflash01,property=secure,value=on \
	  -drive if=pflash,format=raw,unit=0,file=OVMF_CODE.fd,readonly=on \
	  -drive if=pflash,format=raw,unit=1,file=OVMF_VARS.fd \

clean:
	${MAKE} stop
	rm -rf blank.raw img1.cow stages ansible/host qemu.lock qemu.sock qemu.pid *.fd #boot.iso
