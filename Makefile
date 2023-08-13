TARGET := iphone:clang:16.2:15.0
INSTALL_TARGET_PROCESSES = SpringBoard


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TimeBomb

TimeBomb_FILES = Tweak.x
TimeBomb_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
