package com.naman14.arcade.library;

import android.os.AsyncTask;
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

    public void call(final String lua) {
        Log.d("Torch.call(%s)\n", lua);
        new AsyncTask<String,Void,String>() {
            @Override
            protected String doInBackground(String... params) {
                String result = jni_call(assetManager, info.nativeLibraryDir, lua);
                return result;
            }

            @Override
            protected void onPostExecute(String s) {
                super.onPostExecute(s);
            }
        }.execute("");
    }

    // native method
    private native String jni_call(AssetManager manager, String path, String luafile);

}
