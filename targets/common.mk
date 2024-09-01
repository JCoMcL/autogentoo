%/:
	mkdir -p $@

.ONESHELL:
ssh/config: options.mk | ssh/key
	#      insert indendation ⮧            ⮦ remove blank lines
	cat <<EOF | sed -e 's/^_/   /' -e '/^$$/d' > $@
	Host $$(basename $$(pwd))
	_Hostname ${SSH_ADDRESS}
	$$(test -n "${SSH_PORT}" && echo_Port ${SSH_PORT})
	_User ${SSH_USER}
	_UserKnownHostsFile /dev/null
	_StrictHostKeyChecking no
	_IdentityFile $$(realpath ssh/key)
	EOF

ssh/key: | ssh/
	ssh-keygen -t ed25519 -qN '' -f $@ -C "TEMPORARY AUTOGENTOO KEY"
ssh/key.pub: ssh/key

ssh-wrapper/ssh: | ssh/config ssh-wrapper/
	echo -e "#!/usr/bin/env sh\n$$(which ssh) -F $$(realpath ssh/config) '$$@' > $@
	chmod +x $@

sshpass-wrapper/ssh: | ssh/config sshpass-wrapper/
	echo -e "#!/usr/bin/env sh\nsshpass -p ${INITIAL_PASSWD} $$(which ssh) -F $$(realpath ssh/config) '$$@'" > $@
	chmod +x $@
