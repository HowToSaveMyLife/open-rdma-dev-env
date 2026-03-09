#!/bin/bash
echo "setting up network..."
mkdir -p /run/systemd/resolve/
echo "nameserver 8.8.8.8" > /run/systemd/resolve/stub-resolv.conf

export http_proxy=http://172.17.0.1:1081
export https_proxy=http://172.17.0.1:1081
export DRIVER_REPO=https://github.com/open-rdma/open-rdma-driver.git
export DRIVER_COMMIT=157973d6d5d57f026c3ee898136c050ceba82560
export RTL_REPO=https://github.com/open-rdma/open-rdma-rtl.git
export RTL_COMMIT=8924575bd12fb75ed783902883cbacfd47c47df8

cd /root
git clone --recursive $DRIVER_REPO ./open-rdma/open-rdma-driver
git clone $RTL_REPO ./open-rdma/open-rdma-rtl

cd ./open-rdma/open-rdma-driver
git checkout $DRIVER_COMMIT
make -j$(nproc)

cd dtld-ibverbs/rdma-core-55.0
./build.sh
cd ../..

cat >> ~/.bashrc << EOF

# Open RDMA Driver Environment
if [ -z "\$LD_LIBRARY_PATH" ]; then
    export LD_LIBRARY_PATH="$(pwd)/dtld-ibverbs/target/debug:$(pwd)/dtld-ibverbs/rdma-core-55.0/build/lib"
else
    export LD_LIBRARY_PATH="$(pwd)/dtld-ibverbs/target/debug:$(pwd)/dtld-ibverbs/rdma-core-55.0/build/lib:\$LD_LIBRARY_PATH"
fi
EOF

export BLUESPECDIR="/root/bsc-2025.01.1-ubuntu-24.04/lib"
export PATH="$PATH:/root/bsc-2025.01.1-ubuntu-24.04/bin"
cd /root/open-rdma/open-rdma-rtl/test/cocotb
git checkout $RTL_COMMIT
make verilog
PYTHON=~/miniconda3/bin/python make compile_verilator