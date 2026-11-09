# Inherit from generic 64-bit device config
$(call inherit-product, $(SRC_TARGET_DIR)/product/generic.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)

# Inherit from creek device configuration
$(call inherit-product, device/xiaomi/creek/device.mk)

PRODUCT_DEVICE := creek
PRODUCT_NAME := aera_creek
PRODUCT_BRAND := Xiaomi
PRODUCT_MODEL := POCO M7 4G
PRODUCT_MANUFACTURER := Xiaomi
PRODUCT_RELEASE_NAME := creek
