package com.naman14.arcade;

import android.os.AsyncTask;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;

import com.naman14.arcade.library.Arcade;
import com.naman14.arcade.library.ArcadeBuilder;
import com.naman14.arcade.library.listeners.IterationListener;
import com.naman14.arcade.library.listeners.ProgressListener;

public class MainActivity extends AppCompatActivity {

    Arcade arcade;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        Toolbar toolbar = (Toolbar) findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);


        new AsyncTask<Void, Void, Void>() {
            @Override
            protected Void doInBackground(Void... params) {
//                try {
//                    new ModelDownloader().run(MainActivity.this);
//                } catch (Exception e) {
//                    e.printStackTrace();
//                }
                ArcadeBuilder builder = new ArcadeBuilder(MainActivity.this);
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

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.menu_main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();

        //noinspection SimplifiableIfStatement
        if (id == R.id.action_settings) {
            return true;
        }

        return super.onOptionsItemSelected(item);
    }
}
