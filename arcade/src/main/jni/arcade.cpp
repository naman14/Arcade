#include <jni.h>
#include <stdio.h>
#include <stdlib.h>
#include "torchandroid.h"
#include <assert.h>

extern "C" {

lua_State *L;

JNIEXPORT jstring JNICALL
Java_com_naman14_arcade_library_Arcade_initialize(JNIEnv *env,
                                                  jobject thiz,
                                                  jobject assetManager,
                                                  jstring nativeLibraryDir_,
                                                  jstring luaFile_) {
    // get native asset manager
    AAssetManager *manager = AAssetManager_fromJava(env, assetManager);
    assert(NULL != manager);
    const char *nativeLibraryDir = env->GetStringUTFChars(nativeLibraryDir_, 0);
    const char *file = env->GetStringUTFChars(luaFile_, 0);

    char buffer[4096]; // buffer for textview output

    buffer[0] = 0;

    *L = inittorch(manager, nativeLibraryDir); // create a lua_State
    assert(NULL != manager);

    // load file
    int ret;
    long size = android_asset_get_size(file);
    if (size != -1) {
        char *filebytes = android_asset_get_bytes(file);
        ret = luaL_dobuffer(L, filebytes, size, "main");
    }

    return env->NewStringUTF(buffer);
}

JNIEXPORT jstring JNICALL
Java_com_naman14_arcade_library_Arcade_stylize(
        JNIEnv *env, jobject thiz, jstring styleImage, jstring contentImage, jstring outputImage,
        jint gpu, jint numIterations, jint imageSize, jstring optimizer, jstring modelFile,
        jstring protoFile,
        jstring backend, jlong styleScale, jstring styleBlendWeights, jstring styleLayers,
        jstring contentLayers, jstring pooling, jlong tvWeight, jlong styleWeight,
        jlong contentWeight,
        jint seed, jint learningRate, jstring init, jboolean normalizeGradients, jint printIter,
        jint saveIter) {

    lua_newtable(L);
    lua_pushstring(L, "/sdcard/examples/inputs/starry_night_crop.png");
    lua_setfield(L, -2, "style_image");

    lua_pushstring(L, "/sdcard/examples/outputs/golden_gate_scream.png");
    lua_setfield(L, -2, "content_image");

    lua_pushstring(L, "/sdcard/profile.png");
    lua_setfield(L, -2, "output_image");

    lua_pushinteger(L, -1);
    lua_setfield(L, -2, "gpu");

    lua_pushinteger(L, 10);
    lua_setfield(L, -2, "num_iterations");

    lua_pushinteger(L, 256);
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

    lua_pushinteger(L, 10);
    lua_setfield(L, -2, "learning_rate");

    lua_pushstring(L, "random");
    lua_setfield(L, -2, "init");

    lua_pushboolean(L, false);
    lua_setfield(L, -2, "normalize_gradients");

    lua_pushinteger(L, 5);
    lua_setfield(L, -2, "print_iter");

    lua_pushinteger(L, 1);
    lua_setfield(L, -2, "save_iter");

    lua_getglobal(L, "stylize");
    lua_insert(L, -2);   // swap table and function into correct order for pcall

    int result = lua_pcall(L, 1, 0, 0);

}

JNIEXPORT jstring JNICALL
Java_com_naman14_arcade_library_Arcade_destroy(JNIEnv *env, jobject thiz) {
    // destroy the Lua State
    lua_close(L);
}

}

