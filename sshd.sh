#!/bin/bash

source /home/container/prepare-env.sh

ssh-keygen-ifne() {
    local key_type="$1"
    local key_path="/home/container/tools/etc/ssh/ssh_host_${key_type}_key"

    # Skip if the key already exists, otherwise generate it
    [ -f "$key_path" ] && return 0

    nss-run ssh-keygen -t "$key_type" -f "$key_path" -N "" -C ""
}

ssh-keygen-ifne rsa
ssh-keygen-ifne ecdsa
ssh-keygen-ifne ed25519
[ -f /home/container/tools/etc/ssh/sshd_config ] || cp -v /home/container/sshd_config /home/container/tools/etc/ssh/sshd_config

chmod 600 /home/container/.ssh/authorized_keys

# Make sure the sftp-server wrapper is executable
chmod +x /home/container/sftp-server.sh

# For Pid file
mkdir -p /tmp/run/

nss-run /home/container/tools/usr/sbin/sshd \
  -f /home/container/tools/etc/ssh/sshd_config -p "${1:-22}" -D -e 2>&1
