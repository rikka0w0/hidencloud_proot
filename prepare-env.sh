#!/bin/bash

TOOLS=/home/container/tools
WORK=/tmp/tools-download

if [ ! -d "$TOOLS" ]; then
    mkdir -p "$WORK/deb" "$TOOLS"
    cd "$WORK/deb"

    apt download squashfs-tools
    apt-cache depends squashfs-tools \
      | awk '/Depends:/ {print $2}' \
      | sed 's/<//; s/>//' \
      | sort -u \
      | xargs -r apt download
    apt download libnss-wrapper

    for deb in ./*.deb; do
        dpkg-deb -x "$deb" "$TOOLS"
    done
fi

export PATH="$TOOLS/usr/bin:$PATH"
export LD_LIBRARY_PATH="$TOOLS/lib/aarch64-linux-gnu:$TOOLS/usr/lib/aarch64-linux-gnu:$TOOLS/lib/x86_64-linux-gnu:$TOOLS/usr/lib/x86_64-linux-gnu:$TOOLS/lib:$TOOLS/usr/lib:${LD_LIBRARY_PATH:-}"

which unsquashfs || true
ldd "$(which unsquashfs)" || true
unsquashfs -version || true

export FEXDIR=/home/container/fex-portable

if [ ! -d "$FEXDIR" ]; then
    echo "FEX not found: $FEXDIR"
    echo "Extracting /home/container/fex-aarch64-hidencloud.tar ..."

    tar -xf /home/container/fex-aarch64-hidencloud.tar -C /home/container

    if [ ! -d "$FEXDIR" ]; then
        echo "Error: extraction finished but $FEXDIR still does not exist" >&2
        exit 1
    fi
fi

export PATH="$FEXDIR/bin:$PATH"
export LD_LIBRARY_PATH="$FEXDIR/lib:${LD_LIBRARY_PATH:-}"

export FEX_ROOTFS=/home/container/.local/share/fex-emu/RootFS/Ubuntu_24_04

if [ ! -f "$FEX_ROOTFS/usr/bin/uname" ]; then
    mkdir -p "$WORK"
    echo "FEX RootFS not found or invalid: $FEX_ROOTFS"
    curl -L -o "$WORK/rootfs.sqsh" https://rootfs.fex-emu.gg/Ubuntu_24_04/2025-12-27/Ubuntu_24_04.sqsh
    mkdir -p "$FEX_ROOTFS"
    unsquashfs -f -d "$FEX_ROOTFS" "$WORK/rootfs.sqsh"
fi

export FEX_PORTABLE=1

export FEX_SILENTLOG=0
export FEX_OUTPUTLOG=stderr
# export FEX_TSOENABLED=0
# export FEX_HOSTFEATURES=disablesve,disableatomics,disableflagm,disableflagm2,disablerng,disablecrypto,disablefcma,disablelrcpc,disablelrcpc2,disableafp,disablepmull128,disablesvebitperm

"$FEXDIR/bin/FEXInterpreter" /usr/bin/uname -m
