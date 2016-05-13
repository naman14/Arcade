package com.naman14.arcade;

import android.content.Context;
import android.content.DialogInterface;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.preference.Preference;
import android.preference.PreferenceFragment;
import android.preference.PreferenceManager;
import android.support.annotation.Nullable;
import android.support.v7.app.AlertDialog;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.text.InputType;
import android.view.MenuItem;
import android.widget.EditText;

/**
 * Created by naman on 13/05/16.
 */
public class SettingsActivity extends AppCompatActivity {

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_settings);
        Toolbar toolbar = (Toolbar) findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        getSupportActionBar().setTitle("Settings");
        getFragmentManager().beginTransaction().replace(R.id.container, new SettingsFragment()).commit();
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if (item.getItemId() == android.R.id.home)
            super.onBackPressed();
        return super.onOptionsItemSelected(item);
    }

    public static class SettingsFragment extends PreferenceFragment implements SharedPreferences.OnSharedPreferenceChangeListener {

        SharedPreferences preferences;

        @Override
        public void onCreate(Bundle savedInstanceState) {
            super.onCreate(savedInstanceState);
            addPreferencesFromResource(R.xml.preferences);

            preferences = PreferenceManager.getDefaultSharedPreferences(getActivity());
            findPreference("preference_iterations").setOnPreferenceClickListener(new Preference.OnPreferenceClickListener() {
                @Override
                public boolean onPreferenceClick(Preference preference) {
                    showEditDialog(getActivity(), preferences, "Number of iterations", "Iterations", "preference_iterations");
                    return true;
                }
            });
            findPreference("preference_style_weight").setOnPreferenceClickListener(new Preference.OnPreferenceClickListener() {
                @Override
                public boolean onPreferenceClick(Preference preference) {
                    showEditDialog(getActivity(), preferences, "Style weight", "Style weight", "preference_style_weight");
                    return true;
                }
            });
            findPreference("preference_content_weight").setOnPreferenceClickListener(new Preference.OnPreferenceClickListener() {
                @Override
                public boolean onPreferenceClick(Preference preference) {
                    showEditDialog(getActivity(), preferences, "Content weight", "Content weight", "preference_content_weight");
                    return true;
                }
            });
            findPreference("preference_defaults").setOnPreferenceClickListener(new Preference.OnPreferenceClickListener() {
                @Override
                public boolean onPreferenceClick(Preference preference) {
                    preferences.edit().putInt("preference_iterations", 15).apply();
                    preferences.edit().putInt("preference_style_weight", 200).apply();
                    preferences.edit().putInt("preference_content_weight", 20).apply();
                    preferences.edit().putInt("preference_image_size", 128).apply();
                    return true;
                }
            });
        }

        @Override
        public void onSharedPreferenceChanged(SharedPreferences sharedPreferences, String key) {
            findPreference(key).setSummary(String.valueOf(preferences.getInt(key, -1)));
        }
    }

    private static void showEditDialog(Context context, final SharedPreferences preferences, String title, String hint, final String key) {
        AlertDialog.Builder alertDialog = new AlertDialog.Builder(context);
        alertDialog.setTitle(title);
        final EditText input = new EditText(context);
        input.setInputType(InputType.TYPE_NUMBER_FLAG_SIGNED);
        input.setHint(hint);
        input.setText(String.valueOf(preferences.getInt(key, -1)));
        alertDialog.setView(input);
        alertDialog.setPositiveButton("Save",
                new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int which) {
                        preferences.edit().putInt(key, Integer.parseInt(input.getText().toString())).apply();
                    }
                });
        alertDialog.show();
    }
}
