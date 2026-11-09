#!/usr/bin/env python3
"""
Patch for wpa_supplicant AIDL registration check on Android 12/13/14 binder.
Bypasses AIDL stability check at 0x2a6a20 with 'mov w0, #0; ret' (00 00 80 52 c0 03 5f d6).
"""
import sys
import os

def patch_binary(src, dst):
    with open(src, 'rb') as f:
        data = bytearray(f.read())

    # Replace registration check function entry with 'mov w0, #0; ret'
    target = bytes.fromhex("fd7bbda9f44f01a9") # standard arm64 function prologue
    offset = 0x2a6a20
    if offset + 8 <= len(data):
        print(f"Patching wpa_supplicant at 0x{offset:x}...")
        data[offset:offset+8] = bytes.fromhex("00008052c0035fd6")
        with open(dst, 'wb') as f:
            f.write(data)
        os.chmod(dst, 0o755)
        print(f"Saved patched wpa_supplicant to {dst}")
    else:
        print(f"Error: offset 0x{offset:x} out of range")

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: python3 patch_wpa_supplicant.py <input_binary> <output_binary>")
        sys.exit(1)
    patch_binary(sys.argv[1], sys.argv[2])
