package com.naman14.arcade;

import android.app.Notification;
import android.app.NotificationManager;
import android.content.Context;
import android.support.v4.app.NotificationCompat;
import android.util.Log;

import com.naman14.arcade.library.ArcadeUtils;
import com.squareup.okhttp.Call;
import com.squareup.okhttp.Interceptor;
import com.squareup.okhttp.MediaType;
import com.squareup.okhttp.OkHttpClient;
import com.squareup.okhttp.Request;
import com.squareup.okhttp.Response;
import com.squareup.okhttp.ResponseBody;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Calendar;

import okio.Buffer;
import okio.BufferedSource;
import okio.ForwardingSource;
import okio.Okio;
import okio.Source;

public final class ModelDownloader {

    private static final String MODEL_URL = "https://dl.dropbox.com/s/b9mmzkke7rst94y/nin_imagenet_conv.caffemodel?dl=1";
    private static final String PROTO_URL = "https://drive.google.com/uc?export=download&id=0ByTrPZ8aLNaddklKTUozZFBKTlE";


    public void run(final Context context) throws Exception {

        Utils.deleteModels();
        final Notificationhelper notificationhelper = new Notificationhelper(context);

        final ProgressListener progressListener = new ProgressListener() {
            @Override
            public void update(long bytesRead, long contentLength, boolean done) {
                if (done) {
                    notificationhelper.completed();
                    Utils.setModelsDownloaded(context, true);
                    Log.d("lol","here");
                    ((MainActivity) context).downloadingModel = false;
                }
                notificationhelper.progressUpdate((int) bytesRead / 1024, (int) contentLength / 1024);
            }
        };

        OkHttpClient client = new OkHttpClient();
        client.networkInterceptors().add(new Interceptor() {
            @Override
            public Response intercept(Chain chain) throws IOException {
                Response originalResponse = chain.proceed(chain.request());
                return originalResponse.newBuilder()
                        .body(new ProgressResponseBody(originalResponse.body(), progressListener))
                        .build();
            }
        });

        Request request1 = new Request.Builder()
                .url(PROTO_URL)
                .build();

        notificationhelper.createNotification(1232, "Downloading models");

        Call protoCall = new OkHttpClient().newCall(request1);
        Response response1 = protoCall.execute();
        if (!response1.isSuccessful()) throw new IOException("Unexpected code " + response1);

        File folder = new File(ArcadeUtils.getModelsDirectory());
        if (!folder.exists())
            folder.mkdirs();
        File protoFile = new File(ArcadeUtils.getModelsDirectory(), ArcadeUtils.getProtoFileName());
        writeToFile(protoFile, response1.body().byteStream());

        Request request2 = new Request.Builder()
                .url(MODEL_URL)
                .build();

        notificationhelper.clearNotification();
        notificationhelper.createNotification(1332, "Downloading models");
        Call modelCall = client.newCall(request2);
        Response response2 = modelCall.execute();
        if (!response1.isSuccessful()) throw new IOException("Unexpected code " + response2);

        File modelFile = new File(ArcadeUtils.getModelsDirectory(), ArcadeUtils.getModelName());
        writeToFile(modelFile, response2.body().byteStream());

    }

    private void writeToFile(File file, InputStream inputStream) {
        try {
            FileOutputStream fileOutputStream = new FileOutputStream(file);

            OutputStream stream = new BufferedOutputStream(fileOutputStream);
            int bufferSize = 1024 * 50;
            byte[] buffer = new byte[bufferSize];
            int len = 0;
            while ((len = inputStream.read(buffer)) != -1) {
                stream.write(buffer, 0, len);
            }
            if (stream != null)
                stream.close();
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private static class ProgressResponseBody extends ResponseBody {

        private final ResponseBody responseBody;
        private final ProgressListener progressListener;
        private BufferedSource bufferedSource;

        public ProgressResponseBody(ResponseBody responseBody, ProgressListener progressListener) {
            this.responseBody = responseBody;
            this.progressListener = progressListener;
        }

        @Override
        public MediaType contentType() {
            return responseBody.contentType();
        }

        @Override
        public long contentLength() {
            try {
                return responseBody.contentLength();
            } catch (IOException e) {
                return -1;
            }
        }

        @Override
        public BufferedSource source() {
            if (bufferedSource == null) {
                try {
                    bufferedSource = Okio.buffer(source(responseBody.source()));
                } catch (IOException e) {
                    return null;
                }
            }
            return bufferedSource;
        }

        private Source source(Source source) {
            return new ForwardingSource(source) {
                long totalBytesRead = 0L;
                long lastByteRead = 0L;

                @Override
                public long read(Buffer sink, long byteCount) throws IOException {
                    long bytesRead = super.read(sink, byteCount);
                    // read() returns the number of bytes read, or -1 if this source is exhausted.
                    totalBytesRead += bytesRead != -1 ? bytesRead : 0;

                    if (bytesRead == -1) {
                        progressListener.update(totalBytesRead, responseBody.contentLength(), true);
                    } else {
                        if (totalBytesRead - lastByteRead > 1024 * 150) {
                            progressListener.update(totalBytesRead, responseBody.contentLength(), false);
                            lastByteRead = totalBytesRead;
                        }
                    }
                    return bytesRead;
                }
            };
        }
    }

    interface ProgressListener {
        void update(long bytesRead, long contentLength, boolean done);
    }

    private class Notificationhelper {

        private Context mContext;
        private int NOTIFICATION_ID = 1;
        private NotificationManager mNotificationManager;
        NotificationCompat.Builder builder;

        public Notificationhelper(Context context) {
            mContext = context;
        }

        public void createNotification(int newtask, String title) {

            mNotificationManager = (NotificationManager) mContext
                    .getSystemService(Context.NOTIFICATION_SERVICE);
            NOTIFICATION_ID = newtask;

            builder = new NotificationCompat.Builder(mContext);

            builder.setAutoCancel(false);
            builder.setContentTitle(title);
            builder.setSmallIcon(R.mipmap.ic_launcher);
            builder.setOngoing(false);
            builder.setWhen(Calendar.getInstance().getTimeInMillis());
            builder.build();

            Notification notification = builder.build();
            mNotificationManager.notify(newtask, notification);

        }

        public void progressUpdate(int progress, int total) {
            builder.setProgress(total, progress, false);
            builder.setNumber(100);
            mNotificationManager.notify(NOTIFICATION_ID, builder.build());
        }

        public void completed() {
            builder.setContentTitle("Download completed");
            builder.setContentText("Models have been downloaded");
            builder.setOngoing(false);
            builder.mActions.clear();
            builder.setProgress(100, 100, false);
            mNotificationManager.notify(NOTIFICATION_ID, builder.build());
        }

        public void clearNotification() {
            mNotificationManager.cancel(NOTIFICATION_ID);
        }
    }
}