#!/bin/sh

set -e

#sudo apt-get -y update
#sudo apt install -y gcc-4.8 gcc-4.8-multilib nasm upx upx-ucl p7zip-full autoconf automake make patch binutils-dev liblzma-dev syslinux isolinux genisoimage

# 添加 Bionic 源（仅用于 GCC 4.8）
echo "deb [trusted=yes] http://archive.ubuntu.com/ubuntu bionic main universe" | sudo tee /etc/apt/sources.list.d/bionic.list

# 更新 apt
sudo apt-get update || true

# 移除冲突的 32 位库
sudo apt remove -y lib32gcc-s1 libx32gcc-s1 2>/dev/null || true

# 安装 GCC 4.8 及相关编译工具（从 Bionic）
sudo apt install -y \
    gcc-4.8 \
    gcc-4.8-multilib \
    g++-4.8 \
    lib32gcc1 \
    libx32gcc1 \
    nasm \
    upx-ucl \
    p7zip-full \
    autoconf \
    automake \
    make \
    patch \
    binutils-dev \
    liblzma-dev \
    syslinux \
    isolinux \
    genisoimage

# 设置 GCC 4.8 为默认
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.8 100
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.8 100

# 验证 GCC
gcc --version

# 如果需要 QEMU，从 Jammy 源安装（不指定版本，用系统默认的）
#if [ ! "$INPUT_USEQEMU" = "1" ]; then
#    exit
#fi

# 移除 Bionic 源，避免影响 QEMU 安装
#sudo rm /etc/apt/sources.list.d/bionic.list
#sudo apt-get update

# 从 Jammy 安装 QEMU
#sudo apt install -y qemu-kvm qemu-system-x86

# 验证 QEMU
#qemu-system-x86_64 --version

if [ ! "$INPUT_USEQEMU" = "1" ]; then
    exit
fi
for test in $grub4dos_src
do
  if [ ! -f $test/grub4dos_version ]; then
        echo 错误的 grub4dos 源码目录
        exit 1
  fi
done

if [ -e /dev/kvm ]; then
    qemu=kvm
else
    qemu=qemu-system-x86_64
fi

sudo apt -y install qemu-kvm genisoimage
genisoimage -hide-joliet boot.catalog -l -joliet-long -no-emul-boot -boot-load-size 4 -o grubdev.iso -v -V "grubdev" -b boot/grldr grubdev
echo "等待开发环境[${qemu}]启动完成，预计需要 3 － 10 分钟...."
sudo $qemu -m 1G -cdrom grubdev.iso -boot d -display none -net user,hostfwd=tcp::22222-:22 -net nic &
time timeout 10m nc -l -p 22223 || exit $?
[ -d ~/.ssh ] || mkdir -p ~/.ssh
[ -f ~/.ssh/known_hosts ] || touch ~/.ssh/known_hosts
[ -f ~/.ssh/config ] || touch ~/.ssh/config
cat ssh_config >> ~/.ssh/config
