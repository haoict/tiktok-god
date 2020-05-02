ARCHS = armv7 arm64 arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = TTGPref
TTGPref_FILES = $(wildcard *.m)
TTGPref_INSTALL_PATH = /Library/PreferenceBundles
TTGPref_PRIVATE_FRAMEWORKS = Preferences
TTGPref_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/TTGPref.plist$(ECHO_END)
