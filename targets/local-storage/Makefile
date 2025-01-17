include ../facts.mk
include ../common.mk

# TODO add abstraction for systemd and runit
sshd:
	rc-service sshd status | grep  started  >/dev/null || \
		exit 1 # sshd is not started, you can start it with the following command: rc-service sshd start
	ssh localhost true || \
		exit 1 # can't ssh to localhost, you can likely fix this with the following command: ssh-copy-id localhost

ssh-wrapper/ssh: sshd
	rc-service sshd status | grep started

stages/01-sshd: sshpass-wrapper/ssh stages/00-interactive sendkeys.rb
	${MAKE} resume-00-interactive
	./sendkeys.rb 'passwd<ret><delay>${INITIAL_PASSWD}<ret>${INITIAL_PASSWD}<ret><delay>rc-service sshd start<ret>' | socat - ./qemu.sock
	while ! $< -p ${HOST_SSH_PORT} root@127.0.0.1 true; do sleep 3; done
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
		${QEMU} -cdrom boot.iso img1.cow -loadvm $* & echo $$! > qemu.pid;\
	fi
	sleep 3 #FIXME

resume: not-currently-running | stages/00-interactive
	${MAKE} resume-`ls stages | tail -n 1`

stop:
	if ${MAKE} currently-running; then\
		if ! timeout 5 scripts/qemu-cmd.sh quit; then\
			kill `<qemu.pid`;\
			rm qemu.pid ;\
		fi;\
	fi

and-then-boot: stages/05-reboot OVMF_CODE.fd OVMF_VARS.fd
	${MAKE} stop
	${QEMU} img1.cow\
	  -machine q35,smm=on,accel=kvm \
	  -global driver=cfi.pflash01,property=secure,value=on \
	  -drive if=pflash,format=raw,unit=0,file=OVMF_CODE.fd,readonly=on \
	  -drive if=pflash,format=raw,unit=1,file=OVMF_VARS.fd \
clean:
	${MAKE} stop
	rm -rf blank.raw img1.cow stages ansible/host sendkeys.rb qemu.lock qemu.sock qemu.pid *.fd #boot.iso
