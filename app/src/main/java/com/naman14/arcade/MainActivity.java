package com.naman14.arcade;

import android.Manifest;
import android.animation.ArgbEvaluator;
import android.animation.ObjectAnimator;
import android.content.DialogInterface;
import android.content.Intent;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.preference.PreferenceManager;
import android.provider.MediaStore;
import android.support.v7.app.AlertDialog;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.Toolbar;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewPropertyAnimator;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import com.naman14.arcade.library.ArcadeBuilder;
import com.naman14.arcade.library.ArcadeUtils;
import com.nostra13.universalimageloader.core.DisplayImageOptions;
import com.nostra13.universalimageloader.core.ImageLoader;
import com.nostra13.universalimageloader.core.display.FadeInBitmapDisplayer;
import com.nostra13.universalimageloader.core.listener.SimpleImageLoadingListener;

import org.json.JSONArray;
import org.json.JSONException;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.List;

import pub.devrel.easypermissions.EasyPermissions;

public class MainActivity extends AppCompatActivity implements EasyPermissions.PermissionCallbacks {

    Button style, content, start, stop;
    RecyclerView styleRecyclerView;
    ImageView stylizedImage, styleImagePreview;
    View foregroundView, logoView;
    TextView styleButtonText, stylingLog;

    private static final int PICK_STYLE_IMAGE = 777;
    private static final int PICK_CONTENT_IMAGE = 888;

    private ArcadeBuilder builder;
    private LogFragment logFragment;

    private int currentState = 1;
    private static final int STATE_CONTENT_CHOOSE = 1;
    private static final int STATE_STYLE_CHOOSE = 2;
    private static final int STATE_BEGIN_STYLING = 3;
    private static final int STATE_STYLING = 4;

    public boolean downloadingModel = false;

    private String contentPath;
    private String stylePath;

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
        stop = (Button) findViewById(R.id.stopStyling);
        stylingLog = (TextView) findViewById(R.id.stylingLog);

        styleRecyclerView = (RecyclerView) findViewById(R.id.styles_recyclerview);
        styleRecyclerView.setLayoutManager(new LinearLayoutManager(this, LinearLayoutManager.HORIZONTAL, false));

        builder = new ArcadeBuilder(MainActivity.this);
        checkModelExists();

        style.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (checkPermission()) {
                    Intent i = new Intent(Intent.ACTION_PICK,
                            android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
                    startActivityForResult(i, PICK_STYLE_IMAGE);
                }
            }
        });

        content.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (checkPermission()) {
                    Intent i = new Intent(Intent.ACTION_PICK,
                            android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
                    startActivityForResult(i, PICK_CONTENT_IMAGE);
                }
            }
        });

        start.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (checkModelExists()) {
                    currentState = STATE_STYLING;
                    animateViewVisiblity(styleImagePreview, false);
                    animateViewVisiblity(start, false);
                    animateForegroundView(Color.parseColor("#88000000"), Color.parseColor("#11000000"));
                    beginStyling();
                }
            }
        });

        PreferenceManager.setDefaultValues(this, R.xml.preferences, false);


    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.menu_main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        int id = item.getItemId();
        switch (id) {
            case android.R.id.home:
                onBackPressed();
                break;
            case R.id.action_settings:
                startActivity(new Intent(MainActivity.this, SettingsActivity.class));
                break;
        }

        return super.onOptionsItemSelected(item);
    }

    private void beginStyling() {
        if (Utils.getFullLogsEnabled(this))
            setupLogFragment();
        Intent intent = new Intent(this, ArcadeService.class);
        intent.putExtra("style_path", stylePath);
        intent.putExtra("content_path", contentPath);
        startService(intent);

    }

    @Override
    public void onBackPressed() {
        switch (currentState) {
            case STATE_CONTENT_CHOOSE:
                super.onBackPressed();
                break;
            case STATE_STYLE_CHOOSE:
                getSupportActionBar().setDisplayHomeAsUpEnabled(false);
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
                    getSupportActionBar().setDisplayHomeAsUpEnabled(true);
                    stylePath = filePath;
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
                    contentPath = filePath;
                    content.setVisibility(View.GONE);
                    getSupportActionBar().setDisplayHomeAsUpEnabled(true);
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

    public void onStyleImageChoosen(final String filePath, final String name) {
        currentState = STATE_BEGIN_STYLING;
        ImageLoader.getInstance().loadImage(Uri.fromFile(new File(filePath)).toString(), new SimpleImageLoadingListener() {
            @Override
            public void onLoadingComplete(String imageUri, View view, Bitmap loadedImage) {
                SaveToDevice save = new SaveToDevice(loadedImage, name);
                save.execute();
            }
        });

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

    private class SaveToDevice extends AsyncTask<Void, Void, String> {

        Bitmap bitmap;
        String name;

        public SaveToDevice(Bitmap bitmap, String name) {
            this.bitmap = bitmap;
            this.name = name;
        }

        @Override
        protected String doInBackground(Void... params) {
            String root = Environment.getExternalStorageDirectory().toString();
            File myDir = new File(root + "/Arcade/Inputs");

            if (!myDir.exists())
                myDir.mkdirs();

            File file = new File(myDir.getAbsolutePath(), name.replaceAll("\\s+", "") + ".png");
            if (file.exists()) file.delete();
            try {
                FileOutputStream out = new FileOutputStream(file);
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, out);
                out.flush();
                out.close();

            } catch (Exception e) {
                e.printStackTrace();
                return null;
            }
            return file.getAbsolutePath();
        }

        @Override
        protected void onPostExecute(String result) {
            if (result != null) {
                stylePath = result;
                hideStyleImages();
                moveStyleButton(false);
                animateViewVisiblity(start, true);
                ImageLoader.getInstance().displayImage(Uri.fromFile(new File(result)).toString(), styleImagePreview);
                animateStylePreview();
            } else Toast.makeText(MainActivity.this, "Error occurred", Toast.LENGTH_SHORT).show();
        }

        @Override
        protected void onPreExecute() {
        }
    }

    private boolean checkPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            String[] perms = {Manifest.permission.WRITE_EXTERNAL_STORAGE};
            if (EasyPermissions.hasPermissions(this, perms)) {
                return true;
            } else {
                EasyPermissions.requestPermissions(this, "Arcade needs to access device storage",
                        111, perms);
                return false;
            }
        } else return true;
    }

    private boolean checkModelExists() {
        boolean b = ArcadeUtils.modelExists() && Utils.getModelsDownloaded(this);
        if (!b) {
            Utils.setModelsDownloaded(this, false);
            if (!downloadingModel)
                showModelDownloadDialog();
            else
                Toast.makeText(MainActivity.this, "Models are being downloaded", Toast.LENGTH_SHORT).show();
        }
        return b;
    }

    private void showModelDownloadDialog() {
        AlertDialog.Builder dialog = new AlertDialog.Builder(this);
        dialog.setTitle("Download required models");
        dialog.setMessage("Arcade will need to download additional file models to work.\n(Size ~ 30MB)");
        dialog.setCancelable(true);
        dialog.setPositiveButton("Download", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {

                if (checkPermission()) {
                    new AsyncTask<Void, Void, Void>() {
                        @Override
                        protected Void doInBackground(Void... params) {
                            try {
                                downloadingModel = true;
                                new ModelDownloader().run(MainActivity.this);
                                runOnUiThread(new Runnable() {
                                    @Override
                                    public void run() {
                                        Toast.makeText(MainActivity.this, "Downloading models", Toast.LENGTH_SHORT).show();
                                    }
                                });

                            } catch (Exception e) {
                                downloadingModel = false;
                                e.printStackTrace();
                                runOnUiThread(new Runnable() {
                                    @Override
                                    public void run() {
                                        Toast.makeText(MainActivity.this, "Error downloading models", Toast.LENGTH_SHORT).show();
                                    }
                                });
                            }
                            return null;
                        }

                    }.execute();
                }
            }
        });
        dialog.create().show();

    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);

        EasyPermissions.onRequestPermissionsResult(requestCode, permissions, grantResults, this);
    }

    @Override
    public void onPermissionsGranted(int requestCode, List<String> list) {

    }

    @Override
    public void onPermissionsDenied(int requestCode, List<String> list) {

    }
}
