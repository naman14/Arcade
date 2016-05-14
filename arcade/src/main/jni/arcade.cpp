#include <jni.h>
#include <stdio.h>
#include <stdlib.h>
#include "torchandroid.h"
#include <assert.h>
#include <android/log.h>

extern "C" {

lua_State *L;
JNIEnv *globalEnv;

//called from lua
static void onProgressUpdate(lua_State *L) {

    int n = lua_gettop(L);
    int i;

    size_t len;
    const char *log = lua_tolstring(L, 1, &len);

    jclass clazz = globalEnv->FindClass("com/naman14/arcade/library/Arcade");
    jmethodID onProgressUpdate = globalEnv->GetStaticMethodID(clazz, "onProgressUpdate",
                                                              "(Ljava/lang/String;)V");

    jstring logString = globalEnv->NewStringUTF(log);
    globalEnv->CallStaticVoidMethod(clazz, onProgressUpdate, logString);
    globalEnv->DeleteLocalRef(logString);
    globalEnv->DeleteLocalRef(clazz);

}

//called from lua
static void onImageSaved(lua_State *L) {

    int n = lua_gettop(L);
    int i;

    size_t len;
    const char *path = lua_tolstring(L, 1, &len);

    jclass clazz = globalEnv->FindClass("com/naman14/arcade/library/Arcade");
    jmethodID onImageSaved = globalEnv->GetStaticMethodID(clazz, "onImageSaved",
                                                          "(Ljava/lang/String;)V");

    jstring pathString = globalEnv->NewStringUTF(path);
    globalEnv->CallStaticVoidMethod(clazz, onImageSaved, pathString);
    globalEnv->DeleteLocalRef(pathString);
    globalEnv->DeleteLocalRef(clazz);

}

//called from lua
static void onIterationUpdate(lua_State *L) {
    int n = lua_gettop(L);
    int i;

    int currentIteration = lua_tonumber(L, 1);
    int totalIterations = lua_tonumber(L, 2);

    jclass clazz = globalEnv->FindClass("com/naman14/arcade/library/Arcade");
    jmethodID onIterationUpdate = globalEnv->GetStaticMethodID(clazz, "onIterationUpdate",
                                                               "(II)V");

    globalEnv->CallStaticVoidMethod(clazz, onIterationUpdate, currentIteration, totalIterations);
    globalEnv->DeleteLocalRef(clazz);

}

static void onCompleted(lua_State *L) {

    jclass clazz = globalEnv->FindClass("com/naman14/arcade/library/Arcade");
    jmethodID onCompleted = globalEnv->GetStaticMethodID(clazz, "onCompleted",
                                                         "()V");
    globalEnv->CallStaticVoidMethod(clazz, onCompleted);
    globalEnv->DeleteLocalRef(clazz);

}

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

    L = inittorch(manager, nativeLibraryDir); // create a lua_State
    assert(NULL != manager);

    globalEnv = env;

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

    const char *styleImageNative = env->GetStringUTFChars(styleImage, 0);
    const char *contentImageNative = env->GetStringUTFChars(contentImage, 0);
    const char *outputImageNative = env->GetStringUTFChars(outputImage, 0);
    const char *optimizerNative = env->GetStringUTFChars(optimizer, 0);
    const char *modelFileNative = env->GetStringUTFChars(modelFile, 0);
    const char *protoFileNative = env->GetStringUTFChars(protoFile, 0);
    const char *backendNative = env->GetStringUTFChars(backend, 0);
    const char *blendWeightsNative = env->GetStringUTFChars(styleBlendWeights, 0);
    const char *styleLayersNative = env->GetStringUTFChars(styleLayers, 0);
    const char *contentLayersNative = env->GetStringUTFChars(contentLayers, 0);
    const char *poolingNative = env->GetStringUTFChars(pooling, 0);
    const char *initNative = env->GetStringUTFChars(init, 0);

    lua_newtable(L);
    lua_pushstring(L, styleImageNative);
    lua_setfield(L, -2, "style_image");

    lua_pushstring(L, contentImageNative);
    lua_setfield(L, -2, "content_image");

    lua_pushstring(L, outputImageNative);
    lua_setfield(L, -2, "output_image");

    lua_pushinteger(L, gpu);
    lua_setfield(L, -2, "gpu");

    lua_pushinteger(L, numIterations);
    lua_setfield(L, -2, "num_iterations");

    lua_pushinteger(L, imageSize);
    lua_setfield(L, -2, "image_size");

    lua_pushstring(L, optimizerNative);
    lua_setfield(L, -2, "optimizer");

    lua_pushstring(L, modelFileNative);
    lua_setfield(L, -2, "model_file");

    lua_pushstring(L, protoFileNative);
    lua_setfield(L, -2, "proto_file");

    lua_pushstring(L, backendNative);
    lua_setfield(L, -2, "backend");

    luaT_pushlong(L, styleScale);
    lua_setfield(L, -2, "style_scale");

    lua_pushstring(L, blendWeightsNative);
    lua_setfield(L, -2, "style_blend_weights");

    lua_pushstring(L, styleLayersNative);
    lua_setfield(L, -2, "style_layers");

    lua_pushstring(L, contentLayersNative);
    lua_setfield(L, -2, "content_layers");

    lua_pushstring(L, poolingNative);
    lua_setfield(L, -2, "pooling");

    luaT_pushlong(L, tvWeight);
    lua_setfield(L, -2, "tv_weight");

    luaT_pushlong(L, styleWeight);
    lua_setfield(L, -2, "style_weight");

    luaT_pushlong(L, contentWeight);
    lua_setfield(L, -2, "content_weight");

    lua_pushinteger(L, seed);
    lua_setfield(L, -2, "seed");

    lua_pushinteger(L, learningRate);
    lua_setfield(L, -2, "learning_rate");

    lua_pushstring(L, initNative);
    lua_setfield(L, -2, "init");

    lua_pushboolean(L, normalizeGradients);
    lua_setfield(L, -2, "normalize_gradients");

    lua_pushinteger(L, printIter);
    lua_setfield(L, -2, "print_iter");

    lua_pushinteger(L, saveIter);
    lua_setfield(L, -2, "save_iter");

    lua_getglobal(L, "stylize");
    lua_insert(L, -2);   // swap table and function into correct order for pcall

    int result = lua_pcall(L, 1, 0, 0);

    env->ReleaseStringUTFChars(styleImage, styleImageNative);
    env->ReleaseStringUTFChars(contentImage, contentImageNative);
    env->ReleaseStringUTFChars(outputImage, outputImageNative);
    env->ReleaseStringUTFChars(protoFile, protoFileNative);
    env->ReleaseStringUTFChars(modelFile, modelFileNative);
    env->ReleaseStringUTFChars(init, initNative);
    env->ReleaseStringUTFChars(styleBlendWeights, blendWeightsNative);
    env->ReleaseStringUTFChars(pooling, poolingNative);
    env->ReleaseStringUTFChars(styleLayers, styleLayersNative);
    env->ReleaseStringUTFChars(contentLayers, contentLayersNative);
    env->ReleaseStringUTFChars(backend, backendNative);
    env->ReleaseStringUTFChars(optimizer, optimizerNative);


}

JNIEXPORT jstring JNICALL
Java_com_naman14_arcade_library_Arcade_destroy(JNIEnv *env, jobject thiz) {
    // destroy the Lua State
    lua_close(L);
}

JNIEXPORT void JNICALL
Java_com_naman14_arcade_library_Arcade_setProgressListener(JNIEnv *env) {
    lua_CFunction function = (lua_CFunction) onProgressUpdate;
    lua_pushcfunction(L, function);
    lua_setglobal(L, "updateProgress");
}

JNIEXPORT void JNICALL
Java_com_naman14_arcade_library_Arcade_setIterationListener(JNIEnv *env) {
    lua_CFunction function = (lua_CFunction) onIterationUpdate;
    lua_pushcfunction(L, function);
    lua_setglobal(L, "updateIteration");
}

JNIEXPORT void JNICALL
Java_com_naman14_arcade_library_Arcade_setImageSavedListener(JNIEnv *env) {
    lua_CFunction function = (lua_CFunction) onImageSaved;
    lua_pushcfunction(L, function);
    lua_setglobal(L, "onImageSaved");
}

JNIEXPORT void JNICALL
Java_com_naman14_arcade_library_Arcade_setCompletionListener(JNIEnv *env) {
    lua_CFunction function = (lua_CFunction) onCompleted;
    lua_pushcfunction(L, function);
    lua_setglobal(L, "onCompleted");
}


}

