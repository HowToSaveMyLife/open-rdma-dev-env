#!/bin/bash
echo "setting up network..."
mkdir -p /run/systemd/resolve/
echo "nameserver 8.8.8.8" > /run/systemd/resolve/stub-resolv.conf

export http_proxy=http://172.17.0.1:1081
export https_proxy=http://172.17.0.1:1081
export DRIVER_REPO=https://github.com/open-rdma/open-rdma-driver.git
export DRIVER_COMMIT=879ade66292ff04ae69427c5daefe7355f530fc3
export RTL_REPO=https://github.com/open-rdma/open-rdma-rtl.git
export RTL_COMMIT=6ae3d22e9dcd93499c3f4d13be68d0c0f875a5c2

cd /root
git clone --recursive $DRIVER_REPO ./open-rdma/open-rdma-driver
git clone $RTL_REPO ./open-rdma/open-rdma-rtl

cd ./open-rdma/open-rdma-driver
git checkout $DRIVER_COMMIT
make -j$(nproc)

export BLUESPECDIR="/root/bsc-2025.01.1-ubuntu-24.04/lib"
export PATH="$PATH:/root/bsc-2025.01.1-ubuntu-24.04/bin"
cd /root/open-rdma/open-rdma-rtl/test/cocotb
git checkout $RTL_COMMIT
make verilog