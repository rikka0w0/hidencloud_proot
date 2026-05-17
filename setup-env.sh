#!/bin/bash

source /home/container/prepare-env.sh

if [ ! -d "$TOOLS" ]; then
    mkdir -p "$WORK/deb" "$TOOLS"

    # Necessary packages
    apt-nonroot-install squashfs-tools liblzo2-2
    apt-nonroot-install libnss-wrapper
    apt-nonroot-install openssh-server openssh-sftp-server libwrap0
    apt-nonroot-install sslh libpcre3 libconfig9

    # Additional utility packages
    apt-nonroot-install screen libutempter0
    apt-nonroot-install htop libnl-3-200 libnl-genl-3-200
fi

# Check if unsquashfs is available and working
which unsquashfs || true
ldd "$(which unsquashfs)" || true
unsquashfs -version || true

# Extract FEX binary tar ball, if needed
if [ ! -d "$FEXDIR" ]; then
    echo "FEX not found: $FEXDIR"
    echo "Extracting /home/container/fex-aarch64-hidencloud.tar ..."

    tar -xf /home/container/fex-aarch64-hidencloud.tar -C /home/container

    if [ ! -d "$FEXDIR" ]; then
        echo "Error: extraction finished but $FEXDIR still does not exist" >&2
        exit 1
    fi
fi

# Download RootFS, if needed
if [ ! -f "$FEX_ROOTFS/usr/bin/uname" ]; then
    mkdir -p "$WORK"
    echo "FEX RootFS not found or invalid: $FEX_ROOTFS"
    curl -L -o "$WORK/rootfs.sqsh" https://rootfs.fex-emu.gg/Ubuntu_24_04/2025-12-27/Ubuntu_24_04.sqsh
    mkdir -p "$FEX_ROOTFS"
    unsquashfs -f -d "$FEX_ROOTFS" "$WORK/rootfs.sqsh"
fi

# Check if FEXInterpreter is working
"$FEXDIR/bin/FEXInterpreter" /usr/bin/uname -m

# Setup psudo passwd and group for nss-run()
grep -v '^container:' /etc/passwd > /tmp/passwd
echo 'container:x:997:986::/home/container:/bin/bash' >> /tmp/passwd
grep -v '^container:' /etc/group > /tmp/group
echo 'container:x:986:' >> /tmp/group

# Clean the temp working dir
[ -d "$WORK" ] && rm -rf "$WORK"

exit 0
