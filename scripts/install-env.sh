#!/bin/bash

# set up network
echo "setting up network..."
mkdir -p /run/systemd/resolve/
echo "nameserver 8.8.8.8" > /run/systemd/resolve/stub-resolv.conf

export http_proxy=http://172.17.0.1:1081
export https_proxy=http://172.17.0.1:1081


# install dependencies
echo "installing dependencies..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    rdma-core \
    linux-headers-6.8.0-94-generic \
    linux-modules-extra-6.8.0-94-generic \
    cmake \
    pkg-config \
    libnl-3-dev \
    libnl-route-3-dev \
    libclang-dev \
    libibverbs-dev \
    build-essential \
    iverilog \
    verilator \
    zlib1g-dev \
    tcl8.6 \
    libtcl8.6 \
    curl \
    git \
    vim


# 安装 Bluespec 编译器
echo "installing Bluespec compiler..."
cd /root
rm -rf bsc-*

wget https://github.com/B-Lang-org/bsc/releases/download/2025.01.1/bsc-2025.01.1-ubuntu-24.04.tar.gz
tar zxf bsc-*

BSC_FILE_NAME=`ls bsc-*.tar.gz`
BSC_DIR_NAME=`basename $BSC_FILE_NAME .tar.gz`
BLUESPEC_HOME=`realpath $BSC_DIR_NAME`

BASH_RC=$HOME/.bashrc

touch $BASH_RC
cat <<EOF >> $BASH_RC
# BSV required env
export BLUESPECDIR="$BLUESPEC_HOME/lib"
export PATH="\$PATH:$BLUESPEC_HOME/bin"
EOF

rm -rf bsc-*.tar.gz
# export BLUESPECDIR="$BLUESPEC_HOME/lib"
# export PATH="$PATH:$BLUESPEC_HOME/bin"


# 安装 Miniconda 和 Python 包
echo "installing Miniconda..."
mkdir -p ~/miniconda3
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
rm ~/miniconda3/miniconda.sh

source ~/miniconda3/bin/activate
conda init --all

pip install cocotb==1.9.2 cocotb-test cocotbext-pcie cocotbext-axi scapy


# set up open-rdma
touch /etc/systemd/system/open-rdma.service
cat <<EOF >> /etc/systemd/system/open-rdma.service
[Unit]
Description=Open RDMA Service
After=network.target

[Service]
Type=simple
ExecStart=/root/scripts/start-open-rdma.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl enable open-rdma.service

ssh-keygen -A
systemctl enable ssh.service


cat <<EOF >> $BASH_RC
# proxy
export http_proxy=http://172.17.0.1:1081
export https_proxy=http://172.17.0.1:1081
. "$HOME/.cargo/env"
EOF

rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/*