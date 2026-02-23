#!/bin/bash
echo "Setting up network interface..."
ip link set ens3 up

cat > /etc/netplan/01-static-ip.yaml << EOF
network:
  version: 2
  ethernets:
    ens3:
      dhcp4: true
      nameservers:
        addresses: [8.8.8.8, 114.114.114.114]
EOF

netplan apply

# install rust toolchain
if ! command -v rustup &> /dev/null
then
    echo "Installing Rust toolchain..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    rustup default stable
    source $HOME/.cargo/env
else
    echo "Rust toolchain already installed."
fi

cd /root/open-rdma/open-rdma-driver
make install

sudo ip addr add 17.34.51.10/24 dev blue0
sudo ip addr add 17.34.51.11/24 dev blue1

allocate_hugepages() {
    local total_memory_mb=$1
    
    original_hugepages=$(cat /proc/sys/vm/nr_hugepages)
    huge_page_size_kb=$(grep Hugepagesize /proc/meminfo | awk '{print $2}')
    huge_page_size_mb=$((huge_page_size_kb / 1024))
    num_pages=$((total_memory_mb / huge_page_size_mb))
    
    echo "Allocating $num_pages huge pages (${total_memory_mb}MB total, ${huge_page_size_mb}MB per page)..."
    
    echo $num_pages > /proc/sys/vm/nr_hugepages
    
    allocated=$(cat /proc/sys/vm/nr_hugepages)
    
    if [ "$allocated" -lt "$num_pages" ]; then
        echo "Failed to allocate requested huge pages. Requested: $num_pages, Allocated: $allocated"
        echo "Reverting to original setting: $original_hugepages huge pages"
        echo $original_hugepages > /proc/sys/vm/nr_hugepages
        return 1
    else
        actual_memory=$((allocated * huge_page_size_mb))
        echo "Successfully allocated $allocated huge pages (${actual_memory}MB)"
        return 0
    fi
}

allocate_hugepages 2048