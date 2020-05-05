ARCHS = armv7 arm64 arm64e
TARGET = iphone:clang:12.2:10.0

INSTALL_TARGET_PROCESSES = TikTok Preferences

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = tiktokgod
tiktokgod_FILES = $(wildcard *.xm *.m)
tiktokgod_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += pref

include $(THEOS_MAKE_PATH)/aggregate.mk
