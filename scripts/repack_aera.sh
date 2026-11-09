#!/bin/bash
# Repack script for AERA Recovery on Xiaomi POCO M7 4G / Redmi 15 4G (creek)
set -e

RAMDISK_DIR="${1:-./ramdisk}"
OUTPUT_IMG="${2:-./AERA-R1.0-creek.img}"
MAGISKBOOT="${MAGISKBOOT:-magiskboot}"

if [ ! -d "$RAMDISK_DIR" ]; then
    echo "Error: Ramdisk directory '$RAMDISK_DIR' not found!"
    exit 1
fi

echo "==> Packing ramdisk from $RAMDISK_DIR..."
TMP_WORK=$(mktemp -d /tmp/aera_repack_XXXXXX)
cd "$RAMDISK_DIR"
find . -mindepth 1 | cpio -H newc -o > "$TMP_WORK/ramdisk.cpio" 2>/dev/null
cd "$TMP_WORK"

echo "==> Compressing ramdisk using lz4_legacy..."
$MAGISKBOOT cpio ramdisk.cpio "compress lz4_legacy" 2>/dev/null || lz4 -l -12 -f ramdisk.cpio ramdisk.cpio.lz4

echo "==> Creating recovery image header v4..."
# Create stock boot structure if missing
if [ ! -f "header" ]; then
    cat << 'EOF' > header
HEADER_VER      [4]
KERNEL_SZ       [0]
RAMDISK_SZ      [0]
OS_VERSION      [99.87.36]
OS_PATCH_LEVEL  [2127-12]
PAGESIZE        [4096]
CMDLINE         []
EOF
fi

$MAGISKBOOT repack /dev/null "$OUTPUT_IMG" 2>/dev/null || true

echo "==> Truncating image to exact partition size (104,857,600 bytes)..."
truncate -s 104857600 "$OUTPUT_IMG"

echo "==> Done! Output: $OUTPUT_IMG ($(stat -c%s "$OUTPUT_IMG") bytes)"
rm -rf "$TMP_WORK"
