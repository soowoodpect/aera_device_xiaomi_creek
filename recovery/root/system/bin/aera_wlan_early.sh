#!/system/bin/sh
PATH=/system/bin:/sbin:/vendor/bin
export PATH
LOG=/tmp/aera_wlan_early.log

log() {
    echo "[aera-wlan-early] uptime=$(cut -d ' ' -f 1 /proc/uptime 2>/dev/null) $*" >> "$LOG"
    echo "[aera-wlan-early] $*" > /dev/kmsg 2>/dev/null || true
}
fail() { log "STOP: $*"; exit 1; }
prop() { getprop "$1" 2>/dev/null; }
loaded() {
    grep -Eq "^($1|wlan) " /proc/modules 2>/dev/null
}

if [ -e /sys/class/net/wlan0 ]; then
    log "wlan0 already present"
    [ "$(prop wifi.driver.ready)" = true ] || setprop wifi.driver.ready true
    exit 0
fi

log "Early WLAN requested"

SLOT=$(getprop ro.boot.slot_suffix 2>/dev/null)

# 1. Mount firmware directories if not yet mounted
if [ ! -d /vendor/firmware_mnt/image ]; then
    mkdir -p /vendor/firmware_mnt
    mount -o ro -t vfat /dev/block/bootdevice/by-name/modem${SLOT} /vendor/firmware_mnt 2>/dev/null || \
    mount -o ro -t vfat /dev/block/bootdevice/by-name/modem /vendor/firmware_mnt 2>/dev/null || \
    mount --bind /firmware /vendor/firmware_mnt 2>/dev/null
fi

if [ ! -d /vendor/bt_firmware/image ]; then
    mkdir -p /vendor/bt_firmware
    mount -o ro -t vfat /dev/block/bootdevice/by-name/bluetooth${SLOT} /vendor/bt_firmware 2>/dev/null || \
    mount -o ro -t vfat /dev/block/bootdevice/by-name/bluetooth /vendor/bt_firmware 2>/dev/null
fi

if [ ! -d /vendor/dsp ]; then
    mkdir -p /vendor/dsp
    mount -o ro -t ext4 /dev/block/bootdevice/by-name/dsp${SLOT} /vendor/dsp 2>/dev/null || \
    mount -o ro -t ext4 /dev/block/bootdevice/by-name/dsp /vendor/dsp 2>/dev/null
fi

if [ ! -d /mnt/vendor/persist ]; then
    mkdir -p /mnt/vendor
    ln -sf /persist /mnt/vendor/persist
fi

# 2. Setup config files and symlinks
mkdir -p /etc/firmware/wlan/qca_cld /vendor/firmware/wlan/qca_cld
if [ -f /vendor/etc/wifi/WCNSS_qcom_cfg.ini ]; then
    ln -sf /vendor/etc/wifi/WCNSS_qcom_cfg.ini /etc/firmware/wlan/qca_cld/WCNSS_qcom_cfg.ini
    ln -sf /vendor/etc/wifi/WCNSS_qcom_cfg.ini /vendor/firmware/wlan/qca_cld/WCNSS_qcom_cfg.ini
fi

# Generate deterministic MAC from serial if not exists
if [ ! -s /etc/firmware/wlan/qca_cld/wlan_mac.bin ]; then
    SERIAL=$(getprop ro.boot.serialno 2>/dev/null || getprop ro.serialno 2>/dev/null || echo "12345678")
    H=$(echo -n "$SERIAL" | sha256sum | tr '[:lower:]' '[:upper:]')
    B1=$(echo "$H" | cut -c1-2)
    B2=$(echo "$H" | cut -c3-4)
    B3=$(echo "$H" | cut -c5-6)
    B4=$(echo "$H" | cut -c7-8)
    B5=$(echo "$H" | cut -c9-10)
    B0="02"
    MAC="${B0}${B1}${B2}${B3}${B4}${B5}"
    printf "Intf0MacAddress=%s\nIntf1MacAddress=%s\nEND\n" "$MAC" "$MAC" > /etc/firmware/wlan/qca_cld/wlan_mac.bin
    chmod 0644 /etc/firmware/wlan/qca_cld/wlan_mac.bin
    log "Generated wlan_mac.bin with MAC $MAC"
fi

# 3. Load modules in order
for mod in rfkill cfg80211 cnss_nl cnss_utils cnss_prealloc qmi_helpers wlan_firmware_service icnss2 rmnet_ctl rmnet_core rmnet_wlan; do
    loaded "$mod" && continue
    for p in "/vendor_dlkm/lib/modules/$mod.ko" "/vendor/lib/modules/$mod.ko" "/lib/modules/$mod.ko"; do
        if [ -f "$p" ]; then
            insmod "$p" 2>> "$LOG"
            break
        fi
    done
done

# Load wlan driver
if ! loaded wlan; then
    for p in "/vendor_dlkm/lib/modules/qca_cld3_wlan.ko" "/vendor/lib/modules/qca_cld3_wlan.ko"; do
        if [ -f "$p" ]; then
            insmod "$p" 2>> "$LOG"
            break
        fi
    done
fi

# 4. Trigger WPSS boot
WPSS_NODE=""
if [ -w /sys/devices/platform/soc/c800000.qcom,icnss/wpss_boot ]; then
    WPSS_NODE="/sys/devices/platform/soc/c800000.qcom,icnss/wpss_boot"
    DELAY_NODE="/sys/devices/platform/soc/c800000.qcom,icnss/wlan_en_delay"
elif [ -w /sys/kernel/icnss/wpss_boot ]; then
    WPSS_NODE="/sys/kernel/icnss/wpss_boot"
    DELAY_NODE="/sys/kernel/icnss/wlan_en_delay"
fi

if [ -n "$WPSS_NODE" ]; then
    if [ ! -e /tmp/aera_wlan_wpss_requested ]; then
        : > /tmp/aera_wlan_wpss_requested
        log "Triggering WPSS boot via $WPSS_NODE"
        [ -n "$DELAY_NODE" ] && [ -w "$DELAY_NODE" ] && printf '1000\n' > "$DELAY_NODE"
        printf '1\n' > "$WPSS_NODE"
    fi
fi

# 5. Wait for wlan0
count=0
while [ "$count" -lt 15 ] && [ ! -e /sys/class/net/wlan0 ]; do
    sleep 1
    count=$((count+1))
done

if [ -e /sys/class/net/wlan0 ]; then
    log "wlan0 available after ${count}s; publishing wifi.driver.ready"
    setprop wifi.driver.ready true
else
    log "WARNING: wlan0 not yet detected, publishing ready anyway for retry"
    setprop wifi.driver.ready true
fi
exit 0
