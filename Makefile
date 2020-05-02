# THEOS_DEVICE_IP = 192.168.1.45

ARCHS = arm64 arm64e
TARGET = iphone:clang:12.2:12.0

INSTALL_TARGET_PROCESSES = TikTok

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = tiktokgod
tiktokgod_FILES = Tweak.xm
tiktokgod_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += pref

include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 SpringBoard"
