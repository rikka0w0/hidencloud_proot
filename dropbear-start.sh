#!/bin/sh
echo "Spawn dropbear on $1"
mkdir -p /etc/dropbear

[ -f /etc/dropbear/dropbear_rsa_host_key ] || \
  dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key

[ -f /etc/dropbear/dropbear_dss_host_key ] || \
  dropbearkey -t dss -f /etc/dropbear/dropbear_dss_host_key

[ -f /etc/dropbear/dropbear_ed25519_host_key ] || \
  dropbearkey -t ed25519 -f /etc/dropbear/dropbear_ed25519_host_key
  
mkdir -p /root/.ssh
chmod 700 /root/.ssh

wget -O /root/.ssh/authorized_keys https://revproxau.rikka114515.workers.dev/authorized_keys.txt
chmod 600 /root/.ssh/authorized_keys

/usr/sbin/dropbear -F -E -p $1
