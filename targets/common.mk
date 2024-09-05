%/:
	mkdir -p $@

include options.mk

define SSH_CONFIG
Host $(notdir $(CURDIR))
:	Hostname ${SSH_ADDRESS}$(if ${SSH_PORT},
:	Port ${SSH_PORT})
:	User ${SSH_USER}
:	StrictHostKeyChecking no
:	IdentityFile $(shell realpath ssh/key)
endef
# The colons are to preserve the whitespace, they are removed with sed afterwards

ssh/config: options.mk | ssh/key
	$(shell cat <<-EOF | sed s/^://> ssh_config
	${SSH_CONFIG}
	EOF)
	cat ssh_config

ssh/key: | ssh/
	ssh-keygen -t ed25519 -qN '' -f $@ -C "TEMPORARY AUTOGENTOO KEY"
ssh/key.pub: ssh/key

ssh-wrapper/ssh: | ssh/config ssh-wrapper/
	echo -e "#!/usr/bin/env sh\n$$(which ssh) -F $$(realpath ssh/config)" '$$@' > $@
	chmod +x $@

sshpass-wrapper/ssh: | ssh/config sshpass-wrapper/
	echo -e "#!/usr/bin/env sh\nsshpass -p ${INITIAL_PASSWD} $$(which ssh) -F $$(realpath ssh/config)" '$$@' | tee $@
	chmod +x $@

.PHONY: ssh-key-setup
