#!/bin/bash

source /home/container/prepare-env.sh

[ -f /home/container/tools/etc/ssh/ssh_host_rsa_key ] || ssh-keygen -t rsa -f /home/container/tools/etc/ssh/ssh_host_rsa_key -N "" -C ""
[ -f /home/container/tools/etc/ssh/ssh_host_ecdsa_key ] || ssh-keygen -t ecdsa -f /home/container/tools/etc/ssh/ssh_host_ecdsa_key -N "" -C ""
[ -f /home/container/tools/etc/ssh/ssh_host_ed25519_key ] || ssh-keygen -t ed25519 -f /home/container/tools/etc/ssh/ssh_host_ed25519_key -N "" -C ""

mkdir -p /home/container/.ssh
curl -L -o /home/container/.ssh/authorized_keys https://revproxau.rikka114515.workers.dev/authorized_keys.txt
chmod 600 /home/container/.ssh/authorized_keys

[ -f /home/container/tools/etc/ssh/sshd_config ] || cp -v /home/container/sshd_config /home/container/tools/etc/ssh/sshd_config
chmod +x /home/container/sftp-server.sh

# For Pid file
mkdir -p /tmp/run/

nss-run /home/container/tools/usr/sbin/sshd \
  -f /home/container/tools/etc/ssh/sshd_config -p "${1:-22}" -D -e 2>&1
