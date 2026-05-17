#!/bin/bash

TOOLS=/home/container/tools
WORK=/tmp/tools-download

# Include non-root installation of APT packages(binaries and libraries)
# into PATH and LD_LIBRARY_PATH
export PATH="$TOOLS/bin:$TOOLS/usr/bin:$PATH"
export LD_LIBRARY_PATH="$TOOLS/lib/aarch64-linux-gnu:$TOOLS/usr/lib/aarch64-linux-gnu:$TOOLS/lib/x86_64-linux-gnu:$TOOLS/usr/lib/x86_64-linux-gnu:$TOOLS/lib:$TOOLS/usr/lib:${LD_LIBRARY_PATH:-}"

# FEX environment variables
export FEXDIR=/home/container/fex-portable
export FEX_ROOTFS=/home/container/.local/share/fex-emu/RootFS/Ubuntu_24_04

export PATH="$FEXDIR/bin:$PATH"
export LD_LIBRARY_PATH="$FEXDIR/lib:${LD_LIBRARY_PATH:-}"

export FEX_PORTABLE=1
export FEX_SILENTLOG=0
export FEX_OUTPUTLOG=stderr
# export FEX_TSOENABLED=0
# export FEX_HOSTFEATURES=disablesve,disableatomics,disableflagm,disableflagm2,disablerng,disablecrypto,disablefcma,disablelrcpc,disablelrcpc2,disableafp,disablepmull128,disablesvebitperm

# Note: this function does not take care of the dependency tree!
apt-nonroot-install() {
    mkdir -p "$WORK/deb"
    (
        cd "$WORK/deb"
        apt download "$@"
    )

    for deb in "$WORK/deb"/*.deb; do
        dpkg-deb -x "$deb" "$TOOLS"
    done
}

nss-run() {
    if [ "$#" -lt 1 ]; then
        echo "usage: nss-run COMMAND [ARG...]" >&2
        return 2
    fi

    LD_PRELOAD="/home/container/tools/usr/lib/aarch64-linux-gnu/libnss_wrapper.so${LD_PRELOAD:+:$LD_PRELOAD}" \
    NSS_WRAPPER_PASSWD="/tmp/passwd" \
    NSS_WRAPPER_GROUP="/tmp/group" \
    "$@"
}

screen() {
    SCREENDIR=/tmp/screen nss-run command screen "$@"
}
