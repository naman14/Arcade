package com.naman14.arcade.library;

import android.os.Environment;

import java.io.File;

/**
 * Created by naman on 11/05/16.
 */
public class ArcadeUtils {

    public static boolean modelExists() {
        File modelfile = new File(Environment.getExternalStorageDirectory() + "/Arcade/models/nin_imagenet_conv.caffemodel");
        File protofile = new File(Environment.getExternalStorageDirectory() + "/Arcade/models/train_val.prototxt");

        return modelfile.exists() && protofile.exists();
    }

    public static String getModelPath() {
        return Environment.getExternalStorageDirectory() + "/Arcade/models/nin_imagenet_conv.caffemodel";
    }

    public static String getProtoPath() {
        return Environment.getExternalStorageDirectory() + "/Arcade/models/train_val.prototxt";
    }

    public static String getModelName() {
        return "nin_imagenet_conv.caffemodel";
    }

    public static String getProtoFileName() {
        return "train_val.prototxt";
    }

    public static String getModelsDirectory() {
        return Environment.getExternalStorageDirectory() + File.separator + "Arcade" + File.separator + "models";
    }
}
