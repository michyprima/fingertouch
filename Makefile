include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FingerTouch
FingerTouch_FILES = Tweak.xm
FingerTouch_FRAMEWORKS = UIKit AudioToolbox AVFoundation
include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += fingertouchprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
