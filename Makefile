#  ____                 __  __       _         __ _ _
# / ___|___  _ __ ___  |  \/  | __ _| | _____ / _(_) | ___
#| |   / _ \| '__/ _ \ | |\/| |/ _` | |/ / _ \ |_| | |/ _ \
#| |__| (_) | | |  __/ | |  | | (_| |   <  __/  _| | |  __/
# \____\___/|_|  \___| |_|  |_|\__,_|_|\_\___|_| |_|_|\___|

include options.mk
export PATH := $(abspath scripts):$(PATH)

default: target/checkpoints/06-formatted-disk

target:
	ln -sf $$(find targets -mindepth 1 -maxdepth 1 -type d | umenu -sd 'Which type of target are we deploying to?') $@
	ln -sfr options.mk $@/options.mk

target/%: target
	rule=$@; $(MAKE) -C target $${rule#target/}

target/ssh-wrapper/ssh: target
	${MAKE} -C target ssh-wrapper/ssh

target/checkpoints/06-formatted-disk: target/checkpoints/05-disk-access
	scripts/disk-setup.sh $<

#system-level setup required if running on Gentoo
portage-setup:
	rsync -irv portage/* /etc/portage

.PHONY: gentoo-gpg-keys
gentoo-gpg-keys:
	if ls /usr/share/openpgp-keys/gentoo-release.asc; \
	then gpg --import /usr/share/openpgp-keys/gentoo-release.asc; \
	else gpg --keyserver hkps://keys.gentoo.org --recv-keys; \
	fi

stage3.tar.xz: gentoo-gpg-keys
	scripts/download-files.sh http://distfiles.gentoo.org/releases/$(GENTOO_ARCH)/autobuilds/current-stage3-$(GENTOO_ARCH)-openrc asc xz sha256
	ls *.asc | grep -v *.tar.xz | xargs rm -f # remove any .asc files that don't have a corresponding .tar.xz file
	gpg --verify stage3-$(GENTOO_ARCH)-openrc-*.tar.xz.asc
	sha256sum --check stage3-$(GENTOO_ARCH)-openrc-*.tar.xz.sha256
	ln -sf stage3-$(GENTOO_ARCH)-openrc-*.tar.xz $@

ansible/host: ssh/key
	echo "127.0.0.1:${HOST_SSH_PORT} ansible_user=root ansible_ssh_private_key_file=../$<" > $@

tagets/07-system-unpacked: stages/02-ssh-key ansible/host ssh-wrapper/ssh stage3.tar.xz
	${MAKE} resume-02-ssh-key
	env PATH="ssh-wrapper:$(PATH)" ansible-playbook -i ansible/host -vvv ansible/pb.yaml

clean:
	for targ in targets/*/; do $(MAKE) -C $$targ clean || true; done
	rm -rf target

really-clean: clean
	rm -f stage3*.tar.xz
	rm -f stage3*.tar.xz.asc
	rm -f stage3*.tar.xz.sha256

.PHONY: clean reset currently-running not-currently-running
