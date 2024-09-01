%/:
	mkdir -p $@

# This is broken and will need to be redone using Make's "define". ONESHELL is more destructive than I thought and so a heredoc won't really work
ssh/config: options.mk | ssh/key
	#      insert indendation ⮧            ⮦ remove blank lines
	cat <<EOF | sed -e 's/^_/   /' -e '/^$$/d' > $@
	Host $$(basename $$(realpath .))
	_Hostname ${SSH_ADDRESS}
	$$(test -n "${SSH_PORT}" && echo Port ${SSH_PORT})
	_User ${SSH_USER}
	_UserKnownHostsFile /dev/null
	_StrictHostKeyChecking no
	_IdentityFile $$(realpath ssh/key)
	EOF

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
