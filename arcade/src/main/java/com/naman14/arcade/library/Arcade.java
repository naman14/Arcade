package com.naman14.arcade.library;

import android.os.AsyncTask;
import android.provider.Settings;
import android.util.Log;
import android.content.res.AssetManager;
import android.content.pm.ApplicationInfo;
import android.content.Context;

public class Arcade {

    AssetManager assetManager;
    ApplicationInfo info;

    static {
        System.loadLibrary("png16");
        System.loadLibrary("arcade");
    }

    public Arcade(Context context) {
        assetManager = context.getAssets();
        info = context.getApplicationInfo();
    }

    public Arcade(Context context, ArcadeBuilder builder) {

    }

//    public void call(final String lua) {
//        Log.d("Torch.call(%s)\n", lua);
//        new AsyncTask<String, Void, String>() {
//            @Override
//            protected String doInBackground(String... params) {
//                String result = jni_call(assetManager, info.nativeLibraryDir, lua);
//                return result;
//            }
//
//            @Override
//            protected void onPostExecute(String s) {
//                super.onPostExecute(s);
//            }
//        }.execute("");
//    }

    // native method
    private native String stylize(AssetManager manager, String path, String luafile);

}
