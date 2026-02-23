FROM ubuntu:24.04 AS downloader

ENV HTTP_PROXY="http://172.17.0.1:1081"
ENV HTTPS_PROXY="http://172.17.0.1:1081"
ENV KERNEL_SRC=/lib/modules/6.8.0-94-generic/build

ARG DRIVER_REPO=https://github.com/open-rdma/open-rdma-driver.git
ARG RTL_REPO=https://github.com/open-rdma/open-rdma-rtl.git
ARG IMG_URL=https://cloud-images.ubuntu.com/noble/20260131/noble-server-cloudimg-amd64-root.tar.xz
ARG ROOTFS_DIR=/root/ubuntu-24.04

WORKDIR /root

RUN apt-get update && apt-get install -y \
    # Compile kernel modules
    build-essential \
    linux-modules-extra-6.8.0-94-generic \
    linux-image-6.8.0-94-generic \
    linux-headers-6.8.0-94-generic \
    # Additional tools
    libguestfs-tools \
    tmux \
    vim \
    wget \
    git && \
    git clone --recursive $DRIVER_REPO open-rdma/open-rdma-driver && \
    git clone $RTL_REPO open-rdma/open-rdma-rtl && \
    wget $IMG_URL -O ubuntu-24.04.img && \
    rm -rf /var/lib/apt/lists/*

FROM downloader AS builder

COPY scripts ./scripts

RUN ls -l /proc
RUN cd open-rdma/open-rdma-driver && \
    make -j$(nproc) && \
    cd ../.. && \
    mkdir -p $ROOTFS_DIR && \
    tar -Jxf ubuntu-24.04.img -C $ROOTFS_DIR && \
    echo "root:root" | chpasswd -R $ROOTFS_DIR && \
    cp -r open-rdma $ROOTFS_DIR/root/ && \
    cp -r scripts $ROOTFS_DIR/root/open-rdma/ && \
    # mount -t proc /proc /root/ubuntu-24.04/proc && \
    chroot $ROOTFS_DIR /usr/bin/bash < ./scripts/install-env.sh 2>&1 | tee /root/install.log && \
    virt-make-fs --label cloudimg-rootfs --format=qcow2 --type=ext4 --size=+5G $ROOTFS_DIR rootfs.qcow2 && \
    rm -rf $ROOTFS_DIR ubuntu-24.04.img

# rust downloading has problem(no /proc in chroot)
# maybe use privileged docker and mount /proc to chroot env
# docker run --privileged
# mount -t proc /proc /root/ubuntu-24.04/proc
#
# umount /root/ubuntu-24.04/proc