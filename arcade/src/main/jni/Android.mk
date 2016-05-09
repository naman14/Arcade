LOCAL_PATH := $(call my-dir)


include $(CLEAR_VARS)

LOCAL_MODULE := arcade

LOCAL_C_INCLUDES += ../include

LOCAL_SRC_FILES := torchdemo.cpp

LOCAL_LDLIBS := -llog -landroid

include $(BUILD_SHARED_LIBRARY)

# Add prebuilt libimage
include $(CLEAR_VARS)
LOCAL_MODULE := libimage
LOCAL_SRC_FILES := prebuilts/libimage.so
include $(PREBUILT_SHARED_LIBRARY)


# Add prebuilt libloadcaffe
include $(CLEAR_VARS)
LOCAL_MODULE := libloadcaffe
LOCAL_SRC_FILES := prebuilts/libloadcaffe.so
include $(PREBUILT_SHARED_LIBRARY)

# Add prebuilt libtorchandroid
include $(CLEAR_VARS)
LOCAL_MODULE := libtorchandroid
LOCAL_SRC_FILES := prebuilts/libtorchandroid.so
include $(PREBUILT_SHARED_LIBRARY)

# Add prebuilt libluajit
include $(CLEAR_VARS)
LOCAL_MODULE := libluajit
LOCAL_SRC_FILES := prebuilts/libluajit.so
include $(PREBUILT_SHARED_LIBRARY)

# Add prebuilt libluaT
include $(CLEAR_VARS)
LOCAL_MODULE := libluaT
LOCAL_SRC_FILES := prebuilts/libluaT.so
include $(PREBUILT_SHARED_LIBRARY)

# Add prebuilt libTH
include $(CLEAR_VARS)
LOCAL_MODULE := libTH
LOCAL_SRC_FILES := prebuilts/libTH.so
include $(PREBUILT_SHARED_LIBRARY)

# Add prebuilt libtorch
include $(CLEAR_VARS)
LOCAL_MODULE := libtorch
LOCAL_SRC_FILES := prebuilts/libtorch.so
include $(PREBUILT_SHARED_LIBRARY)
