Install QEMU on a x86_64 PC：
```bash
sudo apt update
sudo apt install -y \
  qemu-system-arm \
  qemu-efi-aarch64 \
  cloud-image-utils \
  wget \
  xz-utils \
  openssh-client
```

Download Debian 12 arm64 cloud image
```bash
mkdir -p ~/vm/debian12-arm64
cd ~/vm/debian12-arm64

wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-arm64.qcow2

qemu-img resize debian-12-generic-arm64.qcow2 20G
```

Create cloud-init user profile：
```bash
cat > user-data <<'EOF'
#cloud-config
hostname: fex-build-arm64
manage_etc_hosts: true
users:
  - name: builder
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: sudo
    shell: /bin/bash
    lock_passwd: false
    plain_text_passwd: builder
ssh_pwauth: true
disable_root: false
package_update: true
packages:
  - sudo
  - openssh-server
EOF

cat > meta-data <<'EOF'
instance-id: fex-build-arm64
local-hostname: fex-build-arm64
EOF

cloud-localds seed.img user-data meta-data
```

Boot VM：
```
qemu-system-aarch64 \
  -machine virt \
  -cpu max \
  -smp 4 \
  -m 8192 \
  -bios /usr/share/AAVMF/AAVMF_CODE.fd \
  -drive if=virtio,format=qcow2,file=debian-12-generic-arm64.qcow2 \
  -drive if=virtio,format=raw,file=seed.img \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -device virtio-net-pci,netdev=net0 \
  -nographic
```

SSH into the VM:
```bash
ssh -p 2222 builder@127.0.0.1
# password: builder
```

Inside the VM ssh:
```bash
sudo apt update

sudo apt install -y \
  git \
  cmake \
  ninja-build \
  pkgconf \
  ccache \
  clang \
  llvm \
  lld \
  libssl-dev \
  python3-setuptools \
  g++-x86-64-linux-gnu \
  g++-12-x86-64-linux-gnu \
  libgcc-12-dev-i386-cross \
  libgcc-12-dev-amd64-cross \
  libstdc++-12-dev-i386-cross \
  libstdc++-12-dev-amd64-cross \
  libstdc++-12-dev-arm64-cross \
  squashfs-tools \
  squashfuse

sudo apt install -y \
  git \
  cmake \
  ninja-build \
  pkgconf \
  ccache \
  clang \
  llvm \
  lld \
  binfmt-support \
  libssl-dev \
  python3-setuptools \
  g++-x86-64-linux-gnu \
  g++-12-x86-64-linux-gnu \
  libgcc-12-dev-i386-cross \
  libgcc-12-dev-amd64-cross \
  nasm \
  python3-clang \
  libstdc++-12-dev-i386-cross \
  libstdc++-12-dev-amd64-cross \
  libstdc++-12-dev-arm64-cross \
  squashfs-tools \
  squashfuse \
  libc-bin \
  libc6-dev-i386-amd64-cross \
  lib32stdc++-12-dev-amd64-cross \
  file \
  rsync \
  tar \
  xz-utils
```

Check the env:
```bash
uname -m
dpkg --print-architecture
getconf PAGE_SIZE
ldd --version | head -1
```

expecting:
```
aarch64
arm64
4096
ldd (Debian GLIBC 2.36-9+deb12...)
```

Start building (No FEXConfig, No Thunks):
```
cd /home/builder/FEX

rm -rf build
mkdir build
cd build

cmake .. -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_INSTALL_PREFIX=/home/container/fex-portable \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DBUILD_FEXCONFIG=False \
  -DBUILD_TESTING=False \
  -DBUILD_FEX_LINUX_TESTS=False \
  -DBUILD_THUNKS=False \
  -DENABLE_LTO=True \
  -DUSE_LINKER=lld

ninja -j"$(nproc)"
```

Collect and pack binaries:
```
sudo mkdir -p /home/container/fex-portable
sudo chown -R builder:builder /home/container

ninja install

cd /home/container

tar -cpf /home/builder/fex-portable.tar fex-portable
```
