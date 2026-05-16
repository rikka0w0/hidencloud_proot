#!/bin/sh

export LD_PRELOAD=/home/container/tools/usr/lib/aarch64-linux-gnu/libnss_wrapper.so
export NSS_WRAPPER_PASSWD=/tmp/passwd
export NSS_WRAPPER_GROUP=/tmp/group

exec /home/container/tools/usr/lib/openssh/sftp-server "$@"
