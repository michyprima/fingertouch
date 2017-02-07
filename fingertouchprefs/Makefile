include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = fingertouchprefs
fingertouchprefs_FILES = fttRootListController.m
fingertouchprefs_INSTALL_PATH = /Library/PreferenceBundles
fingertouchprefs_FRAMEWORKS = UIKit
fingertouchprefs_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/fingertouchprefs.plist$(ECHO_END)
