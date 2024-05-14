DISK_SIZE = 10G
MEM = 2G
ARCH = x86_64
HOST_SSH_PORT = 60022
INITIAL_PASSWD = root

SAVE_0 = scripts/fake-savevm.sh
SAVE_1 = scripts/savevm.sh

QEMU = qemu-system-${ARCH} --enable-kvm -m ${MEM} -cdrom boot.iso -nic user,hostfwd=tcp::${HOST_SSH_PORT}-:22 -monitor unix:qemu.sock,server,nowait

%/:
	mkdir -p $@

blank.raw:
	qemu-img create -f raw $@ ${DISK_SIZE}

img1.cow: blank.raw
	qemu-img create -o backing_file=$<,backing_fmt=raw -f qcow2 $@

boot.iso:
	scripts/download-files.sh https://distfiles.gentoo.org/releases/amd64/autobuilds/current-install-amd64-minimal iso
	mv *.iso $@

sshpass-wrapper/ssh: | sshpass-wrapper/
	echo -e "#!/usr/bin/env sh\nsshpass -p ${INITIAL_PASSWD} $$(which ssh) -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" '$$@' > $@
	chmod +x $@

ssh-wrapper/ssh: | ssh-wrapper/
	echo -e "#!/usr/bin/env sh\n$$(which ssh) -p ${HOST_SSH_PORT} -o IdentityFile=ssh/key -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" '$$@' > $@
	chmod +x $@

sendkeys.rb:
	curl https://raw.githubusercontent.com/mvidner/sendkeys/master/sendkeys | install -m 555 /dev/stdin $@

#system-level setup required if running on Gentoo
portage-setup:
	rsync -irv portage/* /etc/portage

stages/00-interactive: boot.iso sendkeys.rb | img1.cow stages/
	${MAKE} not-currently-running || ${MAKE} stop
	${QEMU} -boot once=d -drive file=img1.cow,format=qcow2 & echo $$! > qemu.pid
	echo #Once the system has booted and is in an interactive state, press ENTER to continue
	read
	$(SAVE_1) $(@F) #FIXME logics breaks unless this if this is a fake save

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
		${QEMU} img1.cow -loadvm $* & echo $$! > qemu.pid;\
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

ssh/key: | ssh/
	ssh-keygen -t ed25519 -qN '' -f $@
ssh/key.pub: ssh/key

stages/02-ssh-key: ssh/key.pub sshpass-wrapper/ssh stages/01-sshd
	${MAKE} resume-01-sshd
	env PATH="sshpass-wrapper:$$PATH" ssh-copy-id -i $< -p ${HOST_SSH_PORT} root@127.0.0.1
	$(SAVE_1) $(@F)

stage3-amd64-openrc.tar.xz:
	scripts/download-files.sh http://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-openrc xz sha265
	sha256sum --check stage3-amd64-openrc-*.tar.xz.sha256 # don't know what good this does, they come from the same source
	ln -sf stage3-amd64-openrc-*.tar.xz $@

#ANSIBLE SECTION

ansible/host: ssh/key
	echo "127.0.0.1:${HOST_SSH_PORT} ansible_user=root ansible_ssh_private_key_file=../$<" > $@

stages/03-system-unpacked: stages/02-ssh-key ansible/host ssh-wrapper/ssh stage3-amd64-openrc.tar.xz
	${MAKE} resume-02-ssh-key
	env PATH="ssh-wrapper:$(PATH)" ansible-playbook -i ansible/host -vvv ansible/pb.yaml
	$(SAVE_0) $(@F)

stages/04-unnamed-stage: stages/03-system-unpacked ansible/host ssh-wrapper/ssh stage3-amd64-openrc.tar.xz
	${MAKE} resume-03-system-unpacked
	env PATH="ssh-wrapper:$(PATH)" ansible-playbook -i ansible/host -vvv ansible/pb2.yaml
	$(SAVE_1) $(@F)

%.fd:
	find /usr /nix -name $@ -exec cp {} . \; -print -quit | grep .

stages/05-reboot: stages/04-unnamed-stage ansible/host ssh-wrapper/ssh stage3-amd64-openrc.tar.xz
	${MAKE} resume-04-unnamed-stage
	env PATH="ssh-wrapper:$(PATH)" ansible-playbook -i ansible/host -vvv ansible/pb3.yaml
	$(SAVE_1) $(@F)


and-then-boot: stages/05-reboot OVMF_CODE.fd OVMF_VARS.fd
	${QEMU} img1.cow -boot order=c,strict=on -machine q35,smm=on,accel=kvm \
	  -global driver=cfi.pflash01,property=secure,value=on \
	  -drive if=pflash,format=raw,unit=0,file=OVMF_CODE.fd,readonly=on \
	  -drive if=pflash,format=raw,unit=1,file=OVMF_VARS.fd \

clean:
	${MAKE} stop
	rm -rf blank.raw img1.cow stages ssh sshpass-wrapper ssh-wrapper ansible/host sendkeys.rb qemu.lock qemu.sock qemu.pid #boot.iso

.PHONY: resume $(RESUME) stop clean reset currently-running not-currently-running
