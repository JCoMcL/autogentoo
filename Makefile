ARCH = x86_64
GENTOO_ARCH = $(subst x86_64,amd64 $(ARCH))
HOST_SSH_PORT = 60022
INITIAL_PASSWD = root

SAVE_0 = scripts/fake-savevm.sh
SAVE_1 = scripts/savevm.sh


target:
	ln -sf $$(find targets -mindepth 1 -type d | umenu -sd 'Which target are we deploying to?') $@

boot.iso:
	scripts/download-files.sh https://distfiles.gentoo.org/releases/amd64/autobuilds/current-install-amd64-minimal iso
	mv *.iso $@

sshpass-wrapper/ssh: | sshpass-wrapper/
	echo -e "#!/usr/bin/env sh\nsshpass -p ${INITIAL_PASSWD} $$(which ssh) -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" '$$@' > $@
	chmod +x $@

ssh-wrapper/ssh: | ssh-wrapper/
	echo -e "#!/usr/bin/env sh\n$$(which ssh) -p ${HOST_SSH_PORT} -o IdentityFile=ssh/key -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" '$$@' > $@
	chmod +x $@

#system-level setup required if running on Gentoo
portage-setup:
	rsync -irv portage/* /etc/portage

ssh/key: | ssh/
	ssh-keygen -t ed25519 -qN '' -f $@
ssh/key.pub: ssh/key

stages/02-ssh-key: ssh/key.pub sshpass-wrapper/ssh stages/01-sshd
	${MAKE} resume-01-sshd
	env PATH="sshpass-wrapper:$$PATH" ssh-copy-id -i $< -p ${HOST_SSH_PORT} root@127.0.0.1
	$(SAVE_1) $(@F)

stage3-amd64-openrc.tar.xz:
	scripts/download-files.sh http://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-openrc xz sha256
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

stages/05-reboot: stages/04-unnamed-stage ansible/host ssh-wrapper/ssh stage3-amd64-openrc.tar.xz
	${MAKE} resume-04-unnamed-stage
	env PATH="ssh-wrapper:$(PATH)" ansible-playbook -i ansible/host -vvv ansible/pb3.yaml
	$(SAVE_1) $(@F)


clean:
	rm -rf stages ssh sshpass-wrapper ansible/host #boot.iso

.PHONY: clean reset currently-running not-currently-running
