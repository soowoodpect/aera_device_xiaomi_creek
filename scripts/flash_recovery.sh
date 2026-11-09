#!/bin/bash
# Fastboot flash helper for AERA Recovery on Xiaomi POCO M7 4G / Redmi 15 4G (creek)
set -e

IMG="${1:-AERA-R1.0-creek.img}"

if [ ! -f "$IMG" ]; then
    echo "Error: Recovery image '$IMG' not found!"
    exit 1
fi

echo "==> Waiting for device in fastboot mode..."
fastboot wait-for-device

echo "==> Flashing recovery image..."
fastboot flash recovery "$IMG"

echo "==> Rebooting to recovery..."
fastboot reboot recovery

echo "==> Device should now be booting into AERA Recovery!"
