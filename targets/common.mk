%/:
	mkdir -p $@

include options.mk

define SSH_CONFIG
Host $(notdir $(CURDIR))
\\n	Hostname ${SSH_ADDRESS}
$(if ${SSH_PORT},
\\n	Port ${SSH_PORT})
\\n	User ${SSH_USER}
\\n	StrictHostKeyChecking no
\\n	IdentityFile $(shell realpath ssh/key)
endef

ssh/config: options.mk | ssh/key
	$(shell echo -ne ${SSH_CONFIG} > $@)

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
