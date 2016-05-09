# Build only ARMv7-A machine code.
APP_ABI := armeabi-v7a
APP_CFLAGS += -fopenmp
APP_LDFLAGS += -fopenmp
APP_PLATFORM := android-14
