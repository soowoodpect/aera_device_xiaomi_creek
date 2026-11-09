LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),creek)
include $(call all-subdir-makefiles,$(LOCAL_PATH))
endif
