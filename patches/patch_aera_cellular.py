#!/usr/bin/env python3
"""
Patch for aera-cellular-provider binary for Xiaomi POCO M7 4G / Redmi 15 4G (creek).
Bypasses hardcoded checks for 'peridot' and 'ro.aera.boot':
1. Virtual address 0x11e44 (in --probe): SKU check 'ro.boot.hardware.sku == peridot'.
2. Virtual address 0x1127c and 0x11298 (in daemon main()):
   Checks ro.aera.boot == '1' and ro.boot.hardware.sku == 'peridot'.
   Replaced with NOP (1f 20 03 d5).
"""
import sys
import os

def patch_binary(src, dst):
    with open(src, 'rb') as f:
        data = bytearray(f.read())

    # 1. Patch probe check at 0x11e44: 40 01 00 37 -> 20 00 80 52 (mov w0, #1)
    probe_seq = bytes.fromhex("40010037")
    idx = data.find(probe_seq)
    if idx != -1:
        print(f"Found probe check at 0x{idx:x}, patching...")
        data[idx:idx+4] = bytes.fromhex("20008052")
    else:
        print("Probe check sequence not found or already patched")

    # 2. Patch daemon main checks at 0x1127c and 0x11298:
    # 21 04 00 54 -> 1f 20 03 d5 (NOP)
    # 61 03 00 54 -> 1f 20 03 d5 (NOP)
    for target in [bytes.fromhex("21040054"), bytes.fromhex("61030054")]:
        pos = data.find(target)
        if pos != -1:
            print(f"Found daemon check at 0x{pos:x}, patching with NOP...")
            data[pos:pos+4] = bytes.fromhex("1f2003d5")
        else:
            print(f"Target sequence {target.hex()} not found or already patched")

    with open(dst, 'wb') as f:
        f.write(data)
    os.chmod(dst, 0o755)
    print(f"Successfully saved patched binary to {dst}")

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: python3 patch_aera_cellular.py <input_binary> <output_binary>")
        sys.exit(1)
    patch_binary(sys.argv[1], sys.argv[2])
