#!/bin/sh
if [ "$#" -eq 0 ]; then
    set -- /bin/bash --login
fi

mkdir -p /tmp/proot-tmp
mkdir -p /tmp/proot-run

$HOME/arm64-debootstrap-work/tools/proot-v5.3.0-aarch64-static \
  -0 \
  -r $HOME/arm64-debootstrap-work/rootfs-arm64 \
  -b /dev -b /dev/pts -b /proc -b /sys \
  -b '/tmp/proot-tmp:/tmp' \
  -b '/tmp/proot-run:/run' \
  -w / \
  "$@"
