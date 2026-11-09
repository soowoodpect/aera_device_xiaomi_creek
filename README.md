# AERA Project Recovery for Xiaomi POCO M7 4G / Redmi 15 4G (`creek`)

<p align="center">
  <img src="https://raw.githubusercontent.com/soowoodpect/aera_device_xiaomi_creek/main/banner.png" alt="AERA Recovery" width="600" onerror="this.style.display='none'"/>
</p>

Official device tree and recovery configuration for building and running **AERA Project Recovery R1.0** on **Xiaomi POCO M7 4G / Redmi 15 4G** (codename: `creek`).

---

## 📱 Device Specifications

| Parameter | Specification |
| :--- | :--- |
| **Device Model** | Xiaomi POCO M7 4G / Redmi 15 4G |
| **Device Codename** | `creek` |
| **SoC / Chipset** | Qualcomm SM6225 Snapdragon 680 4G (`bengal` / `khaje`) |
| **CPU / GPU** | Octa-core Kryo 265 / Adreno 610 |
| **Display** | 1080 x 2340 pixels, 120Hz |
| **Touch ICs** | FocalTech (`focaltech_ts_i2c`), Novatek (`td4376_spi`), Xiaomi TP |
| **Partition Scheme** | Virtual A/B (VAB) with Dynamic Partitions (`super`) |
| **Recovery Partition** | Dedicated partition (`104,857,600` bytes / 100 MB) |
| **Boot Header** | Android Boot Image Header Version 4 (`v4`) |
| **Maintainer** | **soowood** (`soowoodpect`) |

---

## 🚀 Status & Working Features

| Feature | Status | Notes |
| :--- | :---: | :--- |
| **Boot & Init** | 🟢 **Working** | Boots cleanly with Android 36 AERA ramdisk |
| **Touchscreen** | 🟢 **Working** | Fixed with vendor touch drivers loaded via `init.recovery.qcom.rc` |
| **DRM Graphics / Display** | 🟢 **Working** | Full native resolution (1080x2340 @ 120Hz) |
| **Dynamic Partitions** | 🟢 **Working** | Super partition mapping (EROFS & EXT4 for system, vendor, product, odm) |
| **ADB & Fastbootd** | 🟢 **Working** | ADB root shell and fastbootd operational |
| **Cellular Modem Subsystem** | 🟢 **Working** | `remoteproc2` MSS + `aera-mobile-rmtfs` + `aera-mobile-tftp` active |
| **AERA Cellular Provider** | 🟡 **WIP** | Daemon starts and connects to QRTR; mobile data IP routing WIP |
| **Wi-Fi Driver Stack** | 🟡 **WIP** | Driver (`icnss2` + `wlan0`) loads; `wpa_supplicant` socket connection unstable |
| **Data Decryption (`/data`)** | 🔴 **Broken** | FBE v2 / Metadata encryption fails (Keystore2 AIDL permission issue) |
| **MTP File Transfer** | 🟡 **Limited** | Works, but internal storage inaccessible until `/data` decryption is resolved |
| **Haptic Feedback** | 🟢 **Working** | `vibratorfeature-hal-service` operational |

---

## ⚠️ Known Issues & Bugs

### 1. 🔴 Internal Storage Decryption (`/data` / FBE v2 Metadata Encryption)
- **Problem**: The `/data` partition (formatted as F2FS) uses hardware-backed metadata encryption with FBE v2. During recovery boot, Vold fails to connect to `keystore2` over AIDL:
  ```
  I:Unable to decrypt metadata encryption
  I:FBE setup failed. Trying FDE...
  E recovery: Vold unable to connect to keystore2.
  W ServiceManagerCppClient: Failed to getService in waitForService for android.system.keystore2.IKeystoreService/default: Status(-129, EX_TRANSACTION_FAILED): 'PERMISSION_DENIED'
  ```
- **Symptom**: The AERA web interface (`https://localhost:8443`) displays *"Unlock internal storage in recovery before transferring installation files"*, and `/data` (`/data/media/0`) remains locked/unmounted.
- **Workaround**: Flash ROMs or ZIP packages using **ADB Sideload** (`adb sideload package.zip`), a **USB-OTG** flash drive, or an external **MicroSD** card.

### 2. 🟡 Wi-Fi Connection via Web UI
- **Problem**: The `icnss2` kernel driver and WLAN firmware load properly, creating the `wlan0` network interface. However, the `wpa_supplicant` control socket (`/tmp/recovery/sockets/wlan0`) intermittently fails to respond to the AERA web interface due to timing and SELinux context mismatches during early boot.
- **Symptom**: Available Wi-Fi networks may fail to appear in the recovery web dashboard or connections may drop.

### 3. 🟡 Screen Suspend / Idle Timeout
- **Problem**: AERA Recovery defaults to a short screen sleep timer, suspending the display after idle timeout (`display suspended by idle timeout`), which can be easily mistaken for a device hang or freeze.
- **Fix / Workaround**: `tw_screen_timeout_secs=0` and `ro.recovery.screen_timeout=0` are configured in `prop.default`. If the display blanks, press the **Power** button to wake it up.

### 4. 🟡 Cellular Mobile Data Routing
- **Problem**: The `aera-cellular-provider` daemon is patched and running with the `remoteproc2` (MSS) modem subsystem and QRTR router. However, automated cellular IP route configuration (APN data provisioning and default routing) is still work-in-progress (WIP).

---


## 📦 Flashing Instructions

### Prerequisites:
- Unlocked bootloader.
- `adb` and `fastboot` installed on your PC.
- Device booted into **Fastboot mode** (`Volume Down` + `Power`).

### Fastboot Flash:

```bash
# 1. Verify device is detected in fastboot
fastboot devices

# 2. Flash recovery image to the dedicated recovery partition
fastboot flash recovery AERA-R1.0-creek.img

# 3. Boot into AERA Recovery
fastboot reboot recovery
```

*For explicit slot-based flashing:*
```bash
fastboot flash recovery_a AERA-R1.0-creek.img
fastboot flash recovery_b AERA-R1.0-creek.img
fastboot reboot recovery
```

---

## 🛠️ Repository Layout

```
├── Android.mk                          # Top-level makefile
├── AndroidProducts.mk                  # Lunch targets definition
├── aera_creek.mk                       # Product configuration
├── BoardConfig.mk                      # Architecture, header v4 & partition specs
├── device.mk                           # Device packages & copy rules
├── recovery.fstab                      # Partition table & mount points
├── recovery/
│   └── root/
│       ├── prop.default                # Device recovery properties (device=creek)
│       ├── init.recovery.qcom.rc       # Vendor firmware mounts & touch module loader
│       ├── init.recovery.cellular.rc   # aera-cellular-provider service definition
│       ├── init.recovery.wifi.rc       # Wi-Fi early bootstrap & wpa_supplicant
│       ├── system/
│       │   ├── bin/
│       │   │   └── aera_wlan_early.sh  # Wi-Fi initialization & MAC address generator
│       │   └── etc/
│       │       ├── recovery.fstab      # Partition layout
│       │       └── twrp.flags          # Backup & flashing flags
│       └── vendor/lib/modules/1.1/     # Essential touch & platform kernel drivers
├── patches/
│   ├── patch_aera_cellular.py          # Bypasses SKU peridot check in daemon & probe
│   └── patch_wpa_supplicant.py         # Bypasses AIDL stability binder registration check
└── scripts/
    ├── repack_aera.sh                  # Packs ramdisk into 100MB boot header v4 image
    └── flash_recovery.sh               # Quick fastboot flashing helper
```

---

## 🔧 Building / Repacking

### Repacking Recovery Image:

```bash
# Export path to magiskboot if not in system PATH
export MAGISKBOOT="/path/to/magiskboot"

# Repack ramdisk into recovery image
./scripts/repack_aera.sh ./recovery/root AERA-R1.0-creek.img
```

The script will automatically:
1. Pack `recovery/root` into `cpio` format.
2. Compress with `lz4_legacy` single-compression.
3. Apply Android boot image header version 4.
4. Truncate/pad the output image to exactly `104,857,600` bytes.

---

## 👥 Credits & Acknowledgments

- **AERA Recovery Project** for the recovery environment and web interface.
- **TeamWin Recovery Project (TWRP)** for base recovery layout and dynamic partition management.
- **topjohnwu** for `magiskboot`.
- Ported and maintained by **soowood** ([@soowoodpect](https://github.com/soowoodpect)).
