#!/bin/bash
# Loop OS QEMU runner
# Boots the seL4 kernel with the Loop system image and displays serial output

KERNEL="external/seL4/build/kernel.elf"
USER_IMG="build/loop-os.bin"

if [ ! -f "$KERNEL" ]; then
    echo "Error: Kernel not found at $KERNEL"
    exit 1
fi

if [ ! -f "$USER_IMG" ]; then
    echo "Error: User image not found at $USER_IMG"
    exit 1
fi

qemu-system-x86_64 \
    -M q35 \
    -m 256M \
    -nographic \
    -serial stdio \
    -kernel "$KERNEL" \
    -initrd "$USER_IMG" \
    -append ""