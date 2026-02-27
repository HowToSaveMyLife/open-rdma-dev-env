#!/bin/bash
set -e

# KVM加速
if [ "${QEMU_KVM}" = "1" ] && [ -e /dev/kvm ]; then
    KVM_OPTS="-enable-kvm -cpu host"
else
    KVM_OPTS="-cpu qemu64"
fi

# 启动QEMU
exec qemu-system-x86_64 \
    $KVM_OPTS \
    -m 16G \
    -smp 16 \
    -kernel /boot/vmlinuz-6.8.0-94-generic \
    -initrd /boot/initrd.img-6.8.0-94-generic \
    -virtfs local,path=/root/share,mount_tag=host0,security_model=mapped-xattr,readonly=off \
    -drive file=/root/rootfs.qcow2,format=qcow2,if=virtio \
    -append "root=LABEL=cloudimg-rootfs rw console=ttyS0" \
    -nographic \
    -netdev user,id=hostnet0,hostfwd=tcp::2222-:22 \
    -device virtio-net-pci,netdev=hostnet0,id=net0