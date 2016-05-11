package com.naman14.arcade.library;

import android.app.Service;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.IBinder;
import android.support.annotation.Nullable;

/**
 * Created by naman on 12/05/16.
 */
public class NeuralStyleService extends Service {

    StylingNotificationHelper notificationHelper;

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {

        notificationHelper = new StylingNotificationHelper(this);

        new AsyncTask<String, Void, String>() {
            @Override
            protected String doInBackground(String... params) {
                return null;
            }
        }.execute("");

        return START_NOT_STICKY;
    }
}
