package com.naman14.arcade;

import android.animation.ArgbEvaluator;
import android.animation.ObjectAnimator;
import android.content.Intent;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
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
import android.view.ViewPropertyAnimator;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.TextView;

import com.naman14.arcade.library.Arcade;
import com.naman14.arcade.library.ArcadeBuilder;
import com.naman14.arcade.library.listeners.IterationListener;
import com.naman14.arcade.library.listeners.ProgressListener;
import com.nostra13.universalimageloader.core.DisplayImageOptions;
import com.nostra13.universalimageloader.core.ImageLoader;
import com.nostra13.universalimageloader.core.display.FadeInBitmapDisplayer;

import org.json.JSONArray;
import org.json.JSONException;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;

public class MainActivity extends AppCompatActivity {

    Button style, content, start;
    RecyclerView styleRecyclerView;
    ImageView stylizedImage, styleImagePreview;
    View foregroundView, logoView;
    TextView styleButtonText;

    private static final int PICK_STYLE_IMAGE = 777;
    private static final int PICK_CONTENT_IMAGE = 888;

    private ArcadeBuilder builder;
    private LogFragment logFragment;

    private int currentState = 1;
    private static final int STATE_CONTENT_CHOOSE = 1;
    private static final int STATE_STYLE_CHOOSE = 2;
    private static final int STATE_BEGIN_STYLING = 3;
    private static final int STATE_STYLING = 4;

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
        styleImagePreview = (ImageView) findViewById(R.id.styleImagePreview);
        foregroundView = findViewById(R.id.foregroundView);
        logoView = findViewById(R.id.logoView);
        styleButtonText = (TextView) findViewById(R.id.pickStyleText);

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
                currentState = STATE_STYLING;
                animateViewVisiblity(styleImagePreview, false);
                animateViewVisiblity(start, false);
                animateForegroundView(Color.parseColor("#88000000"), Color.parseColor("#11000000"));
//                beginStyling();
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

    private void beginStyling() {
        new AsyncTask<Void, Void, Void>() {
            @Override
            protected Void doInBackground(Void... params) {
                Arcade arcade = builder.build();
                arcade.initialize();
                arcade.setLogEnabled(true);
                setupLogFragment();
                arcade.setProgressListener(new ProgressListener() {
                    @Override
                    public void onUpdateProgress(final String log, int currentIteration, int totalIterations) {
                        if (logFragment != null)
                            runOnUiThread(new Runnable() {
                                @Override
                                public void run() {
                                    logFragment.addLog(log);
                                }
                            });
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

    @Override
    public void onBackPressed() {
        switch (currentState) {
            case STATE_CONTENT_CHOOSE:
                super.onBackPressed();
                break;
            case STATE_STYLE_CHOOSE:
                currentState = STATE_CONTENT_CHOOSE;
                content.setVisibility(View.VISIBLE);
                showLogoView();
                hideStyleImages();
                moveStyleButton(false);
                animateViewVisiblity(content, true);
                break;
            case STATE_BEGIN_STYLING:
                currentState = STATE_STYLE_CHOOSE;
                animateViewVisiblity(styleImagePreview, false);
                animateViewVisiblity(start, false);
                animateForegroundView(Color.parseColor("#88000000"), Color.parseColor("#44000000"));
                showStyleImages();
                moveStyleButton(true);
                break;
            case STATE_STYLING:
                break;
        }

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
            Handler handler = new Handler();
            DisplayImageOptions options = new DisplayImageOptions.Builder().displayer(new FadeInBitmapDisplayer(300)).build();
            switch (requestCode) {
                case PICK_STYLE_IMAGE:
                    currentState = STATE_BEGIN_STYLING;
                    builder.setStyleimage(filePath);
                    ImageLoader.getInstance().displayImage(Uri.fromFile(new File(filePath)).toString(), styleImagePreview, options);
                    handler.postDelayed(new Runnable() {
                        @Override
                        public void run() {
                            hideStyleImages();
                            moveStyleButton(false);
                            animateViewVisiblity(start, true);
                            animateStylePreview();
                        }
                    }, 400);

                    break;
                case PICK_CONTENT_IMAGE:
                    builder.setContentImage(filePath);
                    content.setVisibility(View.GONE);
                    currentState = STATE_STYLE_CHOOSE;
                    ImageLoader.getInstance().displayImage(Uri.fromFile(new File(filePath)).toString(), stylizedImage, options);
                    handler.postDelayed(new Runnable() {
                        @Override
                        public void run() {
                            setStylesData();
                            showStyleImages();
                            hideLogoView();
                            animateViewVisiblity(style, true);
                            moveStyleButton(true);
                        }
                    }, 400);

                    break;

            }

        }

    }

    public void onStyleImageChoosen(String filePath) {
        currentState = STATE_BEGIN_STYLING;
        builder.setStyleimage(filePath);
        hideStyleImages();
        moveStyleButton(false);
        animateViewVisiblity(start, true);
        ImageLoader.getInstance().displayImage(Uri.fromFile(new File(filePath)).toString(), styleImagePreview);
        animateStylePreview();
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

    private void setupLogFragment() {
        logFragment = new LogFragment();
        getSupportFragmentManager().beginTransaction().replace(R.id.log_container, logFragment).commit();
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

    private void hideLogoView() {
        logoView.setVisibility(View.VISIBLE);
        logoView.setAlpha(1.0f);
        logoView.animate()
                .setDuration(400)
                .translationY(-logoView.getHeight())
                .alpha(0.0f);
    }

    private void showLogoView() {
        logoView.setVisibility(View.VISIBLE);
        logoView.setTranslationY(-logoView.getHeight());
        logoView.setAlpha(0.0f);
        logoView.animate()
                .setDuration(400)
                .translationY(0)
                .alpha(1.0f);
    }

    private void moveStyleButton(boolean up) {
        style.setVisibility(View.VISIBLE);
        ViewPropertyAnimator animator = style.animate().setDuration(400);
        if (up)
            animator.translationY(-styleRecyclerView.getHeight());
        else animator.translationY(styleRecyclerView.getHeight());
        styleButtonText.setVisibility(View.VISIBLE);
        ViewPropertyAnimator animator2 = styleButtonText.animate().setDuration(400);
        if (up)
            animator2.translationY(-styleRecyclerView.getHeight());
        else animator2.translationY(styleRecyclerView.getHeight());
    }

    private void animateViewVisiblity(View view, boolean visible) {
        if (visible) {
            view.setVisibility(View.VISIBLE);
            view.setAlpha(0.0f);
            view.animate()
                    .setDuration(400)
                    .alpha(1.0f);
        } else {
            view.setAlpha(1.0f);
            view.animate()
                    .setDuration(400)
                    .alpha(0.0f);
        }
    }

    private void animateStylePreview() {
        animateForegroundView(Color.parseColor("#44000000"), Color.parseColor("#88000000"));
        animateViewVisiblity(styleImagePreview, true);
    }

    private void animateForegroundView(int startColor, int endColor) {
        ObjectAnimator animator = ObjectAnimator.ofInt(foregroundView, "backgroundColor", startColor,
                endColor).setDuration(500);
        animator.setEvaluator(new ArgbEvaluator());
        animator.start();
    }

}
