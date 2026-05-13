#!/usr/bin/env bash
set -eu

WORK="$HOME/arm64-debootstrap-work"
TOOLS="$WORK/tools"
ROOTFS="$WORK/rootfs-arm64"
DEB_DIR="/tmp/arm64-debootstrap-debs"

SUITE="bookworm"
MIRROR="https://deb.debian.org/debian"

if [ -d "$WORK" ]; then
  echo "==> Existing setup found at: $WORK"
  echo "==> Skipping all configuration."
  echo "==> To reset, run:"
  echo "    rm -rf \"$WORK\""
  echo "==> Then re-run this script."
  exit 0
fi

mkdir -p "$DEB_DIR" "$TOOLS"

echo "==> Cleaning old local tool root..."
rm -rf "$TOOLS" "$ROOTFS"
mkdir -p "$TOOLS" "$ROOTFS"

echo "==> Downloading Debian packages into $DEB_DIR..."
cd "$DEB_DIR"
rm -f ./*.deb

apt download \
  debootstrap \
  wget \
  fakechroot \
  libfakechroot \
  fakeroot \
  libfakeroot

echo "==> Extracting .deb files into $TOOLS..."
for deb in ./*.deb; do
  echo "    extracting: $deb"
  dpkg-deb -x "$deb" "$TOOLS"
done

echo "==> Creating symlinks normally created by package install scripts..."
if [ -x "$TOOLS/usr/bin/fakeroot-sysv" ]; then
  ln -sf fakeroot-sysv "$TOOLS/usr/bin/fakeroot"
fi

if [ -x "$TOOLS/usr/bin/faked-sysv" ]; then
  ln -sf faked-sysv "$TOOLS/usr/bin/faked"
fi

echo "==> Locating preload libraries..."
FAKEROOT_LIBDIR="$(
  find "$TOOLS/usr/lib" -type f -name 'libfakeroot-sysv.so' -printf '%h\n' 2>/dev/null | head -n 1
)"

FAKECHROOT_LIBDIR="$(
  find "$TOOLS/usr/lib" -type f -name 'libfakechroot.so' -printf '%h\n' 2>/dev/null | head -n 1
)"

if [ -z "${FAKEROOT_LIBDIR:-}" ]; then
  echo "ERROR: libfakeroot-sysv.so not found" >&2
  find "$TOOLS" -name '*fakeroot*' -o -name '*faked*'
  exit 1
fi

if [ -z "${FAKECHROOT_LIBDIR:-}" ]; then
  echo "ERROR: libfakechroot.so not found" >&2
  find "$TOOLS" -name '*fakechroot*'
  exit 1
fi

echo "    FAKEROOT_LIBDIR   = $FAKEROOT_LIBDIR"
echo "    FAKECHROOT_LIBDIR = $FAKECHROOT_LIBDIR"

echo "==> Checking local tools..."
env -i \
  HOME="$HOME" \
  USER="${USER:-container}" \
  LOGNAME="${LOGNAME:-container}" \
  SHELL=/bin/sh \
  PATH="$TOOLS/usr/bin:/usr/bin:/bin" \
  LD_LIBRARY_PATH="$FAKECHROOT_LIBDIR:$FAKEROOT_LIBDIR" \
  "$TOOLS/usr/bin/fakechroot" --version || true

env -i \
  HOME="$HOME" \
  USER="${USER:-container}" \
  LOGNAME="${LOGNAME:-container}" \
  SHELL=/bin/sh \
  PATH="$TOOLS/usr/bin:/usr/bin:/bin" \
  LD_LIBRARY_PATH="$FAKECHROOT_LIBDIR:$FAKEROOT_LIBDIR" \
  "$TOOLS/usr/bin/fakeroot" -v || true

echo "==> Testing fakeroot + fakechroot..."
env -i \
  HOME="$HOME" \
  USER="${USER:-container}" \
  LOGNAME="${LOGNAME:-container}" \
  SHELL=/bin/sh \
  PATH="$TOOLS/usr/bin:/usr/bin:/bin" \
  LD_LIBRARY_PATH="$FAKECHROOT_LIBDIR:$FAKEROOT_LIBDIR" \
  "$TOOLS/usr/bin/fakeroot" \
  "$TOOLS/usr/bin/fakechroot" \
  /usr/bin/whoami

echo "==> Running debootstrap for Debian $SUITE arm64..."
env -i \
  HOME="$HOME" \
  USER="${USER:-container}" \
  LOGNAME="${LOGNAME:-container}" \
  SHELL=/bin/sh \
  PATH="$TOOLS/usr/sbin:$TOOLS/usr/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
  LD_LIBRARY_PATH="$FAKECHROOT_LIBDIR:$FAKEROOT_LIBDIR" \
  DEBOOTSTRAP_DIR="$TOOLS/usr/share/debootstrap" \
  "$TOOLS/usr/bin/fakeroot" \
  "$TOOLS/usr/sbin/debootstrap" \
    --foreign \
    --variant=minbase \
    --arch=arm64 \
    "$SUITE" \
    "$ROOTFS" \
    "$MIRROR" || true

echo "==> Done. Rootfs is at: $ROOTFS"

echo "==> Downloading static proot:"
curl -L -o $TOOLS/proot-v5.3.0-aarch64-static \
  https://github.com/proot-me/proot/releases/download/v5.3.0/proot-v5.3.0-aarch64-static
chmod +x $TOOLS/proot-v5.3.0-aarch64-static

echo "==> Quick check with proot:"
$TOOLS/proot-v5.3.0-aarch64-static --version
PROOT=$HOME/proot.sh
chmod 755 $PROOT
$PROOT /bin/sh -c 'echo inside arm64 rootfs; uname -m; id'

echo "==> Second stage debootstrap:"
$PROOT /usr/bin/env DEBOOTSTRAP_DIR=/debootstrap /debootstrap/debootstrap --second-stage

echo "==> Run first time script:"
cp -v $HOME/rootfs-init.sh /tmp/proot-tmp/
$PROOT /bin/bash /tmp/rootfs-init.sh
