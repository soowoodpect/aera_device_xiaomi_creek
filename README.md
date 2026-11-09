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

## ⚠️ Known Issues & Bugs (Известные проблемы и баги)

### 1. 🔴 Дешифрование данных (`/data` / Internal Storage FBE Decryption)
- **Проблема**: Раздел `/data` (F2FS) зашифрован с использованием аппаратного шифрования метаданных (Metadata Encryption + FBE v2). При загрузке AERA Recovery выдает:
  ```
  I:Unable to decrypt metadata encryption
  I:FBE setup failed. Trying FDE...
  E recovery: Vold unable to connect to keystore2.
  W ServiceManagerCppClient: Failed to getService in waitForService for android.system.keystore2.IKeystoreService/default: Status(-129, EX_TRANSACTION_FAILED): 'PERMISSION_DENIED'
  ```
- **Следствие**: В веб-интерфейсе AERA (`https://localhost:8443`) отображается предупреждение *"Unlock internal storage in recovery before transferring installation files"*, внутренний накопитель (`/data/media/0`) не монтируется.
- **Временный воркэраунд**: Для прошивки zip-файлов используйте **ADB Sideload** (`adb sideload file.zip`), флешку через **USB-OTG** или MicroSD карту.

### 2. 🟡 Подключение к Wi-Fi через веб-интерфейс / UI
- **Проблема**: Драйвер `icnss2` и прошивка WLAN подгружаются успешно, интерфейс `wlan0` создается в системе, однако управляющий сокет `wpa_supplicant` (`/tmp/recovery/sockets/wlan0`) периодически не отвечает графическому интерфейсу AERA из-за таймингов инициализации и SELinux контекстов.
- **Следствие**: Wi-Fi сети могут не отображаться в веб-панели recovery или подключение сбрасывается.

### 3. 🟡 Затухание экрана по таймауту (Display Idle Timeout)
- **Проблема**: По умолчанию в AERA Recovery включен агрессивный таймаут гашения экрана, из-за чего через минуту бездействия дисплей выключается (`display suspended by idle timeout`), что выглядит как зависание устройства.
- **Решение**: Прописаны параметры `tw_screen_timeout_secs=0`, `ro.recovery.screen_timeout=0` в `prop.default`. Если экран погас — достаточно нажать кнопку питания (Power).

### 4. 🟡 Мобильный интернет (Cellular Data)
- **Проблема**: Демон `aera-cellular-provider` пропатчен и запускается под init, модемная подсистема `remoteproc2` и роутер QRTR работают, однако автоматическая маршрутизация трафика мобильных данных (APN / default route) требует доработки сетевого стека.

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
