#
# Copyright (C) 2026 The Android Open Source Project
# Copyright (C) 2026 AERA Project
#
# Maintainer: soowood
#

LOCAL_PATH := device/xiaomi/creek

# QCOM Decryption & Keystore
PRODUCT_PACKAGES += \
    qcom_decrypt \
    qcom_decrypt_fbe

# Recovery Root Files & Scripts
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/recovery/root/init.recovery.qcom.rc:root/init.recovery.qcom.rc \
    $(LOCAL_PATH)/recovery/root/init.recovery.cellular.rc:root/init.recovery.cellular.rc \
    $(LOCAL_PATH)/recovery/root/init.recovery.wifi.rc:root/init.recovery.wifi.rc \
    $(LOCAL_PATH)/recovery/root/prop.default:root/prop.default \
    $(LOCAL_PATH)/recovery/root/system/bin/aera_wlan_early.sh:root/system/bin/aera_wlan_early.sh \
    $(LOCAL_PATH)/recovery/root/system/etc/recovery.fstab:system/etc/recovery.fstab \
    $(LOCAL_PATH)/recovery/root/system/etc/twrp.flags:system/etc/twrp.flags
