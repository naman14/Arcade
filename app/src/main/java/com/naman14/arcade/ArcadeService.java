package com.naman14.arcade;

import android.app.IntentService;
import android.content.Intent;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;
import android.support.v4.content.LocalBroadcastManager;

import com.naman14.arcade.library.Arcade;
import com.naman14.arcade.library.ArcadeBuilder;
import com.naman14.arcade.library.ArcadeUtils;
import com.naman14.arcade.library.listeners.CompletionListener;
import com.naman14.arcade.library.listeners.ImageSavedListener;
import com.naman14.arcade.library.listeners.ProgressListener;

/**
 * Created by naman on 14/05/16.
 */
public class ArcadeService extends IntentService {

    public static final String ACTION_START = "com.naman14.arcade.START";
    public static final String ACTION_COMPLETED = "com.naman14.arcade.COMPLETE";
    public static final String ACTION_IMAGE_SAVED = "com.naman14.arcade.IMAGE_SAVED";
    public static final String ACTION_UPDATE_PROGRESS = "com.naman14.arcade.UPDATE_PROGRESS";

    public static boolean isRunning;
    public static String currentLog;

    public ArcadeService() {
        super("ArcadeService");
    }

    @Override
    protected void onHandleIntent(Intent intent) {
        isRunning = true;
        beginStyling(intent.getStringExtra("style_path"), intent.getStringExtra("content_path"));
    }


    private void beginStyling(String stylePath, String contentPath) {
        ArcadeBuilder builder = new ArcadeBuilder(this);
        SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(this);
        builder.setStyleimage(stylePath);
        builder.setContentImage(contentPath);
        builder.setModelFile(ArcadeUtils.getModelPath());
        builder.setProtoFIle(ArcadeUtils.getProtoPath());
        builder.setImageSize(Integer.parseInt(preferences.getString("preference_image_size", "128")));
        builder.setIterations(Integer.parseInt(preferences.getString("preference_iterations", "15")));
        builder.setSaveIterations(Integer.parseInt(preferences.getString("preference_save_iter", "5")));
        builder.setContentWeight(Integer.parseInt(preferences.getString("preference_content_weight", "20")));
        builder.setStyleWeight(Integer.parseInt(preferences.getString("preference_style_weight", "200")));
        final Arcade arcade = builder.build();
        arcade.initialize();
        arcade.setLogEnabled(true);
        arcade.setProgressListener(new ProgressListener() {
            @Override
            public void onUpdateProgress(final String log, boolean important) {
                Intent localIntent = new Intent(ACTION_UPDATE_PROGRESS);
                localIntent.putExtra("log", log);
                localIntent.putExtra("important", important);
                LocalBroadcastManager.getInstance(ArcadeService.this).sendBroadcast(localIntent);
                if (important)
                    currentLog = log;
            }
        });
        arcade.setImageSavedListener(new ImageSavedListener() {
            @Override
            public void onImageSaved(String path) {
                Intent localIntent = new Intent(ACTION_IMAGE_SAVED);
                localIntent.putExtra("path", path);
                LocalBroadcastManager.getInstance(ArcadeService.this).sendBroadcast(localIntent);
            }
        });
        arcade.setCompletionListsner(new CompletionListener() {
            @Override
            public void onComplete() {
                Intent localIntent = new Intent(ACTION_COMPLETED);
                LocalBroadcastManager.getInstance(ArcadeService.this).sendBroadcast(localIntent);
                isRunning = false;
                stopSelf();
            }
        });
        arcade.stylize();
    }
}
