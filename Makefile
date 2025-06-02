#  ____                 __  __       _         __ _ _
# / ___|___  _ __ ___  |  \/  | __ _| | _____ / _(_) | ___
#| |   / _ \| '__/ _ \ | |\/| |/ _` | |/ / _ \ |_| | |/ _ \
#| |__| (_) | | |  __/ | |  | | (_| |   <  __/  _| | |  __/
# \____\___/|_|  \___| |_|  |_|\__,_|_|\_\___|_| |_|_|\___|

include options.mk

default: target/ssh-wrapper/ssh

target:
	ln -sf $$(find targets -mindepth 1 -maxdepth 1 -type d | umenu -sd 'Which type of target are we deploying to?') $@
	ln -sfr options.mk $@/options.mk

target/ssh-wrapper/ssh: target
	${MAKE} -C target ssh-wrapper/ssh

#system-level setup required if running on Gentoo
portage-setup:
	rsync -irv portage/* /etc/portage


stage3.tar.xz:
	scripts/download-files.sh http://distfiles.gentoo.org/releases/$(GENTOO_ARCH)/autobuilds/current-stage3-$(GENTOO_ARCH)-openrc xz sha256
	sha256sum --check stage3-$(GENTOO_ARCH)-openrc-*.tar.xz.sha256 # don't know what good this does, they come from the same source
	ln -sf stage3-$(GENTOO_ARCH)-openrc-*.tar.xz $@

ansible/host: ssh/key
	echo "127.0.0.1:${HOST_SSH_PORT} ansible_user=root ansible_ssh_private_key_file=../$<" > $@

stages/03-system-unpacked: stages/02-ssh-key ansible/host ssh-wrapper/ssh stage3.tar.xz
	${MAKE} resume-02-ssh-key
	env PATH="ssh-wrapper:$(PATH)" ansible-playbook -i ansible/host -vvv ansible/pb.yaml

stages/04-unnamed-stage: stages/03-system-unpacked ansible/host ssh-wrapper/ssh stage3.tar.xz
	${MAKE} resume-03-system-unpacked
	env PATH="ssh-wrapper:$(PATH)" ansible-playbook -i ansible/host -vvv ansible/pb2.yaml

stages/05-reboot: stages/04-unnamed-stage ansible/host ssh-wrapper/ssh stage3.tar.xz
	${MAKE} resume-04-unnamed-stage
	env PATH="ssh-wrapper:$(PATH)" ansible-playbook -i ansible/host -vvv ansible/pb3.yaml

clean:
	$(MAKE) -C target clean
	rm -rf target

.PHONY: clean reset currently-running not-currently-running
