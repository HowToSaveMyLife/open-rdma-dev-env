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
    build-essential \
    linux-image-6.8.0-94-generic \
    # Additional tools
    libguestfs-tools \
    tmux \
    vim \
    wget && \
    wget $IMG_URL -O ubuntu-24.04.img && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

FROM downloader AS rootfs-builder

COPY scripts ./scripts

RUN mkdir -p /root/share && \
    mkdir -p $ROOTFS_DIR && \
    tar -Jxf ubuntu-24.04.img -C $ROOTFS_DIR && \
    echo "root:root" | chpasswd -R $ROOTFS_DIR && \
    cp -r scripts $ROOTFS_DIR/root/ && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    cp -r ~/.rustup $ROOTFS_DIR/root/.rustup && \
    cp -r ~/.cargo $ROOTFS_DIR/root/.cargo && \
    chroot $ROOTFS_DIR /usr/bin/bash < ./scripts/install-env.sh 2>&1 | tee /root/install.log

FROM rootfs-builder AS final
RUN chroot $ROOTFS_DIR /usr/bin/bash < ./scripts/get-src.sh 2>&1 | tee /root/get-src.log && \
    virt-make-fs --label cloudimg-rootfs --format=qcow2 --type=ext4 --size=+2G $ROOTFS_DIR rootfs.qcow2 && \
    rm -rf $ROOTFS_DIR ubuntu-24.04.img