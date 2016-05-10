package com.naman14.arcade.library;

import android.provider.Settings;
import android.util.Log;
import android.content.res.AssetManager;
import android.content.pm.ApplicationInfo;
import android.content.Context;

public class Torch {
    AssetManager assetManager;
    ApplicationInfo info;

    public Torch(Context myContext) {
        assetManager = myContext.getAssets();
        info = myContext.getApplicationInfo();
        System.loadLibrary("png16");
        System.loadLibrary("arcade");
        Log.d("Torch", "Torch() called\n");
    }

    public String call(String lua) {
        Log.d("Torch.call(%s)\n", lua);
        return jni_call(assetManager, info.nativeLibraryDir, lua);
    }

    // native method
    private native String jni_call(AssetManager manager, String path, String luafile);

}
