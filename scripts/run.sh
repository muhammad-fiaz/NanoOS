#!/bin/bash
# NanoOS Runner for Linux

# Build
zig build
if [ $? -ne 0 ]; then
    echo "Build failed"
    exit 1
fi

# Setup Boot Dir
mkdir -p zig-out/EFI/BOOT
cp zig-out/bin/NanoOS.efi zig-out/EFI/BOOT/BOOTX64.EFI

# Check for OVMF
OVMF_PATH=""
if [ -f "OVMF.fd" ]; then
    OVMF_PATH="OVMF.fd"
elif [ -f "/usr/share/ovmf/OVMF.fd" ]; then
    OVMF_PATH="/usr/share/ovmf/OVMF.fd"
elif [ -f "/usr/share/qemu/OVMF.fd" ]; then
    OVMF_PATH="/usr/share/qemu/OVMF.fd"
fi

if [ -z "$OVMF_PATH" ]; then
    echo "OVMF.fd not found. Please install ovmf or place OVMF.fd in current directory."
    exit 1
fi

echo "Using BIOS: $OVMF_PATH"

# Run QEMU
qemu-system-x86_64 \
    -drive if=pflash,format=raw,readonly=on,file="$OVMF_PATH" \
    -drive format=raw,file=fat:rw:zig-out \
    -net none \
    -serial stdio
