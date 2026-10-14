package by.quake.zircon;

import android.app.Activity;
import android.app.AlertDialog;
import android.graphics.Color;
import android.os.Bundle;
import android.view.Gravity;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.SeekBar;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;

import java.util.Locale;

/** Engine options applied through android_settings.cfg on the next game start. */
public class SettingsActivity extends Activity {

    private EngineSettings settings;
    private float density;
    private Button[] fpsChips;

    private void updateFpsChips() {
        for (int i = 0; i < fpsChips.length; i++) {
            boolean selected = EngineSettings.FPS_CHOICES[i] == settings.maxFps;
            UiStyle.applyKind(fpsChips[i], selected ? UiStyle.Kind.PRIMARY : UiStyle.Kind.SECONDARY, true);
        }
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        settings = EngineSettings.load(this);
        density = getResources().getDisplayMetrics().density;

        LinearLayout box = new LinearLayout(this);
        box.setOrientation(LinearLayout.VERTICAL);
        box.setPadding(dp(32), dp(20), dp(32), dp(20));

        // Done lives in the header so it is reachable without scrolling on a landscape phone
        LinearLayout header = new LinearLayout(this);
        header.setOrientation(LinearLayout.HORIZONTAL);
        header.setGravity(Gravity.CENTER_VERTICAL);
        TextView title = UiStyle.title(this, "Settings", 24);
        header.addView(title, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        header.addView(UiStyle.button(this, "Done", UiStyle.Kind.PRIMARY, v -> finish()));
        box.addView(header);

        TextView note = new TextView(this);
        note.setText("Applied the next time the game starts.");
        note.setPadding(0, dp(4), 0, dp(12));
        box.addView(note);

        slider(box, "3D render scale", 30, 100, Math.round(settings.viewScale * 100), v -> String.format(Locale.US, "%d%%", v),
            v -> settings.viewScale = v / 100f);

        // segmented row instead of a dropdown: every choice stays visible and tappable
        caption(box, "Frame rate limit");
        LinearLayout fpsRow = new LinearLayout(this);
        fpsRow.setOrientation(LinearLayout.HORIZONTAL);
        fpsChips = new Button[EngineSettings.FPS_CHOICES.length];
        for (int i = 0; i < fpsChips.length; i++) {
            final int choice = EngineSettings.FPS_CHOICES[i];
            Button chip = UiStyle.chip(this, choice == 0 ? "Unlimited" : String.valueOf(choice), UiStyle.Kind.SECONDARY, v -> {
                settings.maxFps = choice;
                settings.save(this);
                updateFpsChips();
            });
            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
            lp.rightMargin = dp(8);
            fpsRow.addView(chip, lp);
            fpsChips[i] = chip;
        }
        updateFpsChips();
        box.addView(fpsRow);

        checkbox(box, "Vsync", settings.vsync, b -> settings.vsync = b);
        slider(box, "Look sensitivity", 5, 150, Math.round(settings.lookSensitivity * 100),
            v -> String.format(Locale.US, "%.2f", v / 100f), v -> settings.lookSensitivity = v / 100f);
        checkbox(box, "Invert vertical look", settings.invertLook, b -> settings.invertLook = b);
        checkbox(box, "Show FPS counter", settings.showFps, b -> settings.showFps = b);
        checkbox(box, "Hide touch controls while a gamepad is used", settings.hideOnGamepad, b -> settings.hideOnGamepad = b);

        LinearLayout row = new LinearLayout(this);
        row.setGravity(Gravity.END);
        row.setPadding(0, dp(16), 0, 0);
        Button resetControls = UiStyle.button(this, "Reset all control layouts", UiStyle.Kind.GHOST, null);
        resetControls.setOnClickListener(v -> new AlertDialog.Builder(this, UiStyle.DIALOG_THEME)
            .setTitle("Reset control layouts")
            .setMessage("Delete every saved on-screen control layout and return to the defaults?")
            .setPositiveButton("Reset", (d, w) -> {
                ControlLayout.deleteAllSaved(this);
                Toast.makeText(this, "Control layouts reset", Toast.LENGTH_SHORT).show();
            })
            .setNegativeButton("Cancel", null)
            .show());
        row.addView(resetControls);
        box.addView(row);

        ScrollView scroll = new ScrollView(this);
        scroll.setBackgroundColor(UiStyle.BG);
        UiStyle.applyInsets(scroll);
        scroll.addView(box);
        setContentView(scroll);
    }

    @Override
    protected void onPause() {
        super.onPause();
        settings.save(this);
    }

    private interface IntFormat {
        String format(int value);
    }

    private interface IntSink {
        void set(int value);
    }

    private interface BoolSink {
        void set(boolean value);
    }

    private TextView caption(LinearLayout box, String text) {
        TextView t = new TextView(this);
        t.setText(text);
        t.setTextColor(UiStyle.TEXT_DIM);
        t.setPadding(0, dp(12), 0, dp(2));
        box.addView(t);
        return t;
    }

    private void slider(LinearLayout box, String name, int min, int max, int value, IntFormat format, IntSink sink) {
        TextView label = caption(box, name + ": " + format.format(value));
        SeekBar bar = new SeekBar(this);
        bar.setMax(max - min);
        bar.setProgress(Math.max(0, Math.min(max - min, value - min)));
        UiStyle.tint(bar);
        bar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                label.setText(name + ": " + format.format(progress + min));
                sink.set(progress + min);
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {
            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {
                settings.save(SettingsActivity.this);
            }
        });
        box.addView(bar);
    }

    private void checkbox(LinearLayout box, String text, boolean checked, BoolSink sink) {
        CheckBox cb = new CheckBox(this);
        cb.setText(text);
        cb.setChecked(checked);
        UiStyle.tint(cb);
        cb.setOnCheckedChangeListener((v, b) -> {
            sink.set(b);
            settings.save(this);
        });
        box.addView(cb);
    }

    private int dp(int v) {
        return Math.round(v * density);
    }
}
