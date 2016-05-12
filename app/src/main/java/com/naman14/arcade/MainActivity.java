package com.naman14.arcade;

import android.animation.ObjectAnimator;
import android.content.Intent;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.provider.MediaStore;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.Toolbar;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;

import com.naman14.arcade.library.Arcade;
import com.naman14.arcade.library.ArcadeBuilder;
import com.naman14.arcade.library.listeners.IterationListener;
import com.naman14.arcade.library.listeners.ProgressListener;
import com.nostra13.universalimageloader.core.ImageLoader;

import org.json.JSONArray;
import org.json.JSONException;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;

public class MainActivity extends AppCompatActivity {

    Button style, content, start;
    RecyclerView styleRecyclerView;
    ImageView stylizedImage;
    View foregroundView;

    private static final int PICK_STYLE_IMAGE = 777;
    private static final int PICK_CONTENT_IMAGE = 888;

    private ArcadeBuilder builder;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        Toolbar toolbar = (Toolbar) findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        assert getSupportActionBar() != null;
        getSupportActionBar().setTitle("");

        style = (Button) findViewById(R.id.pickStyle);
        content = (Button) findViewById(R.id.pickContent);
        start = (Button) findViewById(R.id.start);
        stylizedImage = (ImageView) findViewById(R.id.stylizedImage);
        foregroundView = findViewById(R.id.foregroundView);

        styleRecyclerView = (RecyclerView) findViewById(R.id.styles_recyclerview);
        styleRecyclerView.setLayoutManager(new LinearLayoutManager(this, LinearLayoutManager.HORIZONTAL, false));

        style.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent i = new Intent(Intent.ACTION_PICK,
                        android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
                startActivityForResult(i, PICK_STYLE_IMAGE);
            }
        });

        content.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent i = new Intent(Intent.ACTION_PICK,
                        android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
                startActivityForResult(i, PICK_CONTENT_IMAGE);
            }
        });

        start.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                new AsyncTask<Void, Void, Void>() {
                    @Override
                    protected Void doInBackground(Void... params) {
                        Arcade arcade = builder.build();
                        arcade.initialize();
                        arcade.setLogEnabled(true);
                        arcade.setProgressListener(new ProgressListener() {
                            @Override
                            public void onUpdateProgress(String log, int currentIteration, int totalIterations) {

                            }
                        });
                        arcade.setIterationListener(new IterationListener() {
                            @Override
                            public void onIteration(int currentIteration, int totalIteration) {
                                Log.d("iterations", String.valueOf(currentIteration) + " of " + String.valueOf(totalIteration));
                            }
                        });
                        arcade.stylize();
                        return null;
                    }
                }.execute();

            }
        });

        builder = new ArcadeBuilder(MainActivity.this);


    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.menu_main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        int id = item.getItemId();
        if (id == R.id.action_settings) {
            return true;
        }

        return super.onOptionsItemSelected(item);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        if (resultCode == RESULT_OK) {
            Uri selectedImage = data.getData();
            String[] filePathColumn = {MediaStore.Images.Media.DATA};

            Cursor cursor = getContentResolver().query(
                    selectedImage, filePathColumn, null, null, null);
            cursor.moveToFirst();

            int columnIndex = cursor.getColumnIndex(filePathColumn[0]);
            String filePath = cursor.getString(columnIndex);

            String extension = filePath.substring(filePath.lastIndexOf(".") + 1);
            if (extension.equals("jpeg") || extension.equals("jpg") || extension.equals("JPEG")) {
                Bitmap bmp = BitmapFactory.decodeFile(filePath);
                File folder = new File(Environment.getExternalStorageDirectory() + "/Arcade/temp");
                if (!folder.exists())
                    folder.mkdirs();

                File convertedImage;
                if (requestCode == PICK_STYLE_IMAGE)
                    convertedImage = new File(Environment.getExternalStorageDirectory() + "/Arcade/temp/convertedstyleinput.png");
                else
                    convertedImage = new File(Environment.getExternalStorageDirectory() + "/Arcade/temp/convertedcontentinput.png");


                //TODO delete the temp folder when finished

                try {
                    FileOutputStream outStream = new FileOutputStream(convertedImage);
                    boolean success = bmp.compress(Bitmap.CompressFormat.PNG, 100, outStream);
                    outStream.flush();
                    outStream.close();
                    filePath = convertedImage.getAbsolutePath();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }


            cursor.close();

            switch (requestCode) {
                case PICK_STYLE_IMAGE:
                    builder.setStyleimage(filePath);
                    break;
                case PICK_CONTENT_IMAGE:
                    builder.setContentImage(filePath);
                    ImageLoader.getInstance().displayImage(Uri.fromFile(new File(filePath)).toString(), stylizedImage);
                    Handler handler = new Handler();
                    handler.postDelayed(new Runnable() {
                        @Override
                        public void run() {
                            setStylesData();
                            showStyleImages();
                        }
                    }, 500);

                    break;

            }

        }

    }

    private void setStylesData() {
        try {
            JSONArray array = new JSONArray(Utils.loadAssetTextAsString(this, "styleimages.json"));
            StylesAdapter adapter = new StylesAdapter(this, array);
            styleRecyclerView.setAdapter(adapter);
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    private void fadeoutForeground() {
        ObjectAnimator animator = ObjectAnimator.ofFloat(foregroundView, "alpha", 1f, 0f);
        animator.setDuration(200);
        animator.start();
    }

    private void showStyleImages() {
        styleRecyclerView.setVisibility(View.VISIBLE);
        styleRecyclerView.setTranslationY(styleRecyclerView.getHeight());
        styleRecyclerView.setAlpha(0.0f);
        styleRecyclerView.animate()
                .setDuration(400)
                .translationY(0)
                .alpha(1.0f);
    }

    private void hideStyleImages() {
        styleRecyclerView.setVisibility(View.VISIBLE);
        styleRecyclerView.setAlpha(1.0f);
        styleRecyclerView.animate()
                .setDuration(400)
                .translationY(styleRecyclerView.getHeight())
                .alpha(0.0f);
    }
}
