package com.naman14.arcade;

import android.content.SharedPreferences;
import android.os.Bundle;
import android.preference.EditTextPreference;
import android.preference.ListPreference;
import android.preference.Preference;
import android.preference.PreferenceFragment;
import android.preference.PreferenceManager;
import android.preference.SwitchPreference;
import android.support.annotation.Nullable;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.util.Log;
import android.view.MenuItem;

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
            preferences.registerOnSharedPreferenceChangeListener(this);
            findPreference("preference_iterations").setSummary(preferences.getString("preference_iterations", "15"));
            findPreference("preference_style_weight").setSummary(preferences.getString("preference_style_weight", "200"));
            findPreference("preference_content_weight").setSummary(preferences.getString("preference_content_weight", "20"));

            findPreference("preference_defaults").setOnPreferenceClickListener(new Preference.OnPreferenceClickListener() {
                @Override
                public boolean onPreferenceClick(Preference preference) {
                    preferences.edit().putString("preference_iterations", "15").apply();
                    preferences.edit().putString("preference_style_weight", "200").apply();
                    preferences.edit().putString("preference_content_weight", "20").apply();
                    preferences.edit().putString("preference_image_size", "128").apply();
                    preferences.edit().putBoolean("preference_logs", false).apply();
                    findPreference("preference_iterations").setSummary(preferences.getString("preference_iterations", "15"));
                    findPreference("preference_style_weight").setSummary(preferences.getString("preference_style_weight", "200"));
                    findPreference("preference_content_weight").setSummary(preferences.getString("preference_content_weight", "20"));
                    findPreference("preference_image_size").setSummary(preferences.getString("preference_image_size", "128"));
                    ((SwitchPreference) findPreference("preference_logs")).setChecked(preferences.getBoolean("preference_logs", false));

                    return true;
                }
            });
        }

        @Override
        public void onSharedPreferenceChanged(SharedPreferences sharedPreferences, String key) {
            Log.d("lol", "b;bfw;");
            Preference p = findPreference(key);
            if (p instanceof EditTextPreference) {
                EditTextPreference editTextPref = (EditTextPreference) p;
                Log.d("lodsbc", editTextPref.getText());
                p.setSummary(editTextPref.getText());
            } else if (p instanceof ListPreference) {
                ListPreference listPref = (ListPreference) p;
                p.setSummary(listPref.getSummary());
            }
        }
    }
}
