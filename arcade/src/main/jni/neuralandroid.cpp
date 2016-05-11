#include <jni.h>
#include <stdio.h>
#include <stdlib.h>
#include "torchandroid.h"
#include <assert.h>

extern "C" {

JNIEXPORT jstring JNICALL
Java_com_naman14_arcade_library_Torch_jni_1call(JNIEnv *env,
                                                jobject thiz,
                                                jobject assetManager,
                                                jstring nativeLibraryDir_,
                                                jstring luaFile_
) {
    D("Hello from C");
    // get native asset manager
    AAssetManager *manager = AAssetManager_fromJava(env, assetManager);
    assert(NULL != manager);
    const char *nativeLibraryDir = env->GetStringUTFChars(nativeLibraryDir_, 0);
    const char *file = env->GetStringUTFChars(luaFile_, 0);

    char buffer[4096]; // buffer for textview output

    D("Torch.call(%s), nativeLibraryDir=%s", file, nativeLibraryDir);

    buffer[0] = 0;

    lua_State *L = inittorch(manager, nativeLibraryDir); // create a lua_State
    assert(NULL != manager);

    // load and run file
    int ret;
    long size = android_asset_get_size(file);
    if (size != -1) {
        char *filebytes = android_asset_get_bytes(file);
        ret = luaL_dobuffer(L, filebytes, size, "main");
    }

    // check if script ran succesfully. If not, print error to logcat
    if (ret == 1) {
        D("Error doing resource: %s:%s\n", file, lua_tostring(L, -1));
        strlcat(buffer, lua_tostring(L, -1), sizeof(buffer));
    }
    else
        strlcat(buffer,
                "Torch script ran succesfully. Check Logcat for more details.",
                sizeof(buffer));

    lua_newtable(L);
    lua_pushstring(L, "/sdcard/examples/inputs/starry_night_crop.png");
    lua_setfield(L, -2, "style_image");

    lua_pushstring(L, "/sdcard/examples/inputs/starry_night_crop.png");
    lua_setfield(L, -2, "content_image");

    lua_pushstring(L, "/sdcard/profile.png");
    lua_setfield(L, -2, "output_image");

    lua_pushinteger(L, -1);
    lua_setfield(L, -2, "gpu");

    lua_pushinteger(L, 1);
    lua_setfield(L, -2, "num_iterations");

    lua_pushinteger(L, 128);
    lua_setfield(L, -2, "image_size");

    lua_pushstring(L, "adam");
    lua_setfield(L, -2, "optimizer");

    lua_pushstring(L, "/storage/emulated/0/models/nin_imagenet_conv.caffemodel");
    lua_setfield(L, -2, "model_file");

    lua_pushstring(L, "/storage/emulated/0/models/train_val.prototxt");
    lua_setfield(L, -2, "proto_file");

    lua_pushstring(L, "nn");
    lua_setfield(L, -2, "backend");

    luaT_pushlong(L, 1.0);
    lua_setfield(L, -2, "style_scale");

    lua_pushstring(L, "nil");
    lua_setfield(L, -2, "style_blend_weights");

    lua_pushstring(L, "relu0,relu3,relu7,relu12");
    lua_setfield(L, -2, "style_layers");

    lua_pushstring(L, "relu0,relu3,relu7,relu12");
    lua_setfield(L, -2, "content_layers");

    lua_pushstring(L, "avg");
    lua_setfield(L, -2, "pooling");

    luaT_pushlong(L, 0.001);
    lua_setfield(L, -2, "tv_weight");

    luaT_pushlong(L, 200);
    lua_setfield(L, -2, "style_weight");

    luaT_pushlong(L, 10);
    lua_setfield(L, -2, "content_weight");

    lua_pushinteger(L, 123);
    lua_setfield(L, -2, "seed");

    lua_pushstring(L, "random");
    lua_setfield(L, -2, "init");

    lua_pushboolean(L, false);
    lua_setfield(L, -2, "normalize_gradients");

    lua_pushinteger(L, 50);
    lua_setfield(L, -2, "print_iter");

    lua_pushinteger(L, 50);
    lua_setfield(L, -2, "save_iter");

    lua_getglobal(L, "stylize");
    lua_insert(L, -2);   // swap table and function into correct order for pcall
    int result = lua_pcall(L, 1, 0, 0);

    // destroy the Lua State
    // lua_close(L);
    return env->NewStringUTF(buffer);
}
}

