package by.quake.zircon;

import android.app.Activity;
import android.app.AlertDialog;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.text.InputType;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.HorizontalScrollView;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.SeekBar;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

/** Toolbar and dialogs for editing the on-screen controls while the game keeps running underneath. */
final class ControlEditor implements TouchOverlay.Listener {

    private static final String[] TYPE_VALUES = { ControlLayout.TYPE_KEY, ControlLayout.TYPE_COMMAND, ControlLayout.TYPE_KEYBOARD };
    private static final String[] TYPE_LABELS = { "Key (follows binds)", "Console command", "Soft keyboard" };
    private static final String[] MODE_VALUES = { ControlLayout.MODE_HOLD, ControlLayout.MODE_TOGGLE, ControlLayout.MODE_TAP };
    private static final String[] MODE_LABELS = { "Hold", "Toggle", "Tap" };
    private static final String[] SHOW_VALUES = { ControlLayout.SHOW_GAME, ControlLayout.SHOW_CONSOLE, ControlLayout.SHOW_BOTH };
    private static final String[] SHOW_LABELS = { "In game", "Console only", "Game and console" };

    private final Activity activity;
    private final ViewGroup parent;
    private final TouchOverlay overlay;
    private final String gameDir;
    private final float density;

    private FrameLayout frame;
    private HorizontalScrollView barScroll;
    private boolean barAtBottom;
    private Button editButton, hideButton, deleteButton;
    private ControlLayout backup;

    ControlEditor(Activity activity, ViewGroup parent, TouchOverlay overlay, String gameDir) {
        this.activity = activity;
        this.parent = parent;
        this.overlay = overlay;
        this.gameDir = gameDir;
        this.density = activity.getResources().getDisplayMetrics().density;
        overlay.setListener(this);
    }

    boolean isOpen() {
        return frame != null;
    }

    void open() {
        if (frame != null) {
            return;
        }
        backup = overlay.getControlLayout().copy();
        overlay.startEditing();

        LinearLayout bar = new LinearLayout(activity);
        bar.setOrientation(LinearLayout.HORIZONTAL);
        bar.setPadding(dp(8), dp(7), dp(8), dp(7));
        bar.setGravity(Gravity.CENTER_VERTICAL);
        GradientDrawable bg = new GradientDrawable();
        bg.setColor(UiStyle.withAlpha(UiStyle.SURFACE, 0xEE));
        bg.setStroke(Math.max(1, dp(1)), UiStyle.OUTLINE);
        bg.setCornerRadius(dp(26));
        bar.setBackground(bg);

        bar.addView(barButton("Add", v -> addControl()));
        editButton = barButton("Edit", v -> editSelected());
        bar.addView(editButton);
        hideButton = barButton("Hide", v -> toggleSelectedVisible());
        bar.addView(hideButton);
        deleteButton = barButton("Delete", v -> deleteSelected());
        bar.addView(deleteButton);
        bar.addView(barButton("Layout", v -> showLayoutDialog()));
        bar.addView(barButton("Reset", v -> confirmReset()));
        bar.addView(barButton("Move bar", v -> setBarAtBottom(!barAtBottom)));
        bar.addView(barButton("Cancel", UiStyle.Kind.GHOST, v -> close(false)));
        bar.addView(barButton("Save", UiStyle.Kind.PRIMARY, v -> close(true)));

        HorizontalScrollView scroll = new HorizontalScrollView(activity);
        scroll.setHorizontalScrollBarEnabled(false);
        scroll.addView(bar);

        frame = new FrameLayout(activity);
        barScroll = scroll;
        frame.addView(scroll, new FrameLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        setBarAtBottom(false);
        parent.addView(frame, new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));

        onSelectionChanged(null);
        Toast.makeText(activity, "Drag to move, pinch to resize, tap a button to select it", Toast.LENGTH_LONG).show();
    }

    void close(boolean save) {
        if (frame == null) {
            return;
        }
        overlay.stopEditing();
        if (save) {
            try {
                overlay.getControlLayout().save(activity, gameDir);
            } catch (IOException e) {
                Toast.makeText(activity, "Could not save controls: " + e.getMessage(), Toast.LENGTH_LONG).show();
            }
        } else {
            overlay.setControlLayout(backup);
        }
        parent.removeView(frame);
        frame = null;
    }

    @Override
    public void onEditRequested() {
        open();
    }

    /** the bar sits at the top or bottom edge; buttons underneath it cannot be touched until it moves */
    private void setBarAtBottom(boolean bottom) {
        barAtBottom = bottom;
        FrameLayout.LayoutParams lp = (FrameLayout.LayoutParams) barScroll.getLayoutParams();
        lp.gravity = (bottom ? Gravity.BOTTOM : Gravity.TOP) | Gravity.CENTER_HORIZONTAL;
        lp.topMargin = bottom ? 0 : dp(8);
        lp.bottomMargin = bottom ? dp(8) : 0;
        barScroll.setLayoutParams(lp);
    }

    @Override
    public void onSelectionChanged(ControlLayout.Control control) {
        if (frame == null) {
            return;
        }
        boolean has = control != null;
        if (has && (control.y < 0.25f) != barAtBottom) {
            setBarAtBottom(control.y < 0.25f); // keep the selected control uncovered
        }
        editButton.setEnabled(has);
        hideButton.setEnabled(has);
        hideButton.setText(has && !control.visible ? "Show" : "Hide");
        deleteButton.setEnabled(has && control.custom);
    }

    private void addControl() {
        ControlLayout.Control c = new ControlLayout.Control();
        c.id = "custom_" + System.currentTimeMillis();
        c.custom = true;
        c.icon = "text";
        c.label = "BTN";
        c.type = ControlLayout.TYPE_KEY;
        c.action = "SPACE";
        c.mode = ControlLayout.MODE_HOLD;
        c.x = 0.5f;
        c.y = 0.5f;
        c.size = 26;
        overlay.getControlLayout().controls.add(c);
        overlay.refresh();
        overlay.select(c);
        showProperties(c);
    }

    private void editSelected() {
        ControlLayout.Control c = overlay.getSelected();
        if (c != null) {
            showProperties(c);
        }
    }

    private void toggleSelectedVisible() {
        ControlLayout.Control c = overlay.getSelected();
        if (c != null) {
            c.visible = !c.visible;
            overlay.refresh();
            onSelectionChanged(c);
        }
    }

    private void deleteSelected() {
        ControlLayout.Control c = overlay.getSelected();
        if (c != null && c.custom) {
            overlay.getControlLayout().controls.remove(c);
            overlay.select(null);
            overlay.refresh();
        }
    }

    private void confirmReset() {
        dialog()
            .setTitle("Reset controls")
            .setMessage("Restore the default layout for this game? Press Save afterwards to keep it.")
            .setPositiveButton("Reset", (d, w) -> overlay.setControlLayout(ControlLayout.loadDefault(activity)))
            .setNegativeButton("Cancel", null)
            .show();
    }

    private void showLayoutDialog() {
        ControlLayout layout = overlay.getControlLayout();
        LinearLayout box = column();
        SeekBar opacity = slider(box, "Opacity", 20, 100, Math.round(layout.opacity * 100), "%");
        SeekBar size = slider(box, "Button size", 50, 160, Math.round(layout.scale * 100), "%");
        SeekBar zone = slider(box, "Move stick zone width", 20, 70, Math.round(layout.stickZone * 100), "%");
        dialog()
            .setTitle("Layout")
            .setView(box)
            .setPositiveButton("OK", (d, w) -> {
                layout.opacity = (opacity.getProgress() + 20) / 100f;
                layout.scale = (size.getProgress() + 50) / 100f;
                layout.stickZone = (zone.getProgress() + 20) / 100f;
                overlay.refresh();
            })
            .setNegativeButton("Cancel", null)
            .show();
    }

    private void showProperties(ControlLayout.Control c) {
        // two columns: a single column is taller than a landscape phone and hides the action field
        LinearLayout columns = new LinearLayout(activity);
        columns.setOrientation(LinearLayout.HORIZONTAL);
        columns.setPadding(dp(12), 0, dp(12), 0);
        LinearLayout left = column();
        LinearLayout right = column();
        columns.addView(left, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        columns.addView(right, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));

        Spinner type = spinner(left, "Action type", TYPE_LABELS, indexOf(TYPE_VALUES, c.type));
        EditText action = field(left, "Key name or console command", c.action, false);
        Button pickKey = UiStyle.chip(activity, "Pick key…", UiStyle.Kind.SECONDARY, v -> dialog()
            .setTitle("Key")
            .setItems(keyNames(), (d, which) -> {
                action.setText(keyNames()[which]);
                type.setSelection(0);
            })
            .show());
        LinearLayout.LayoutParams pickLp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        pickLp.topMargin = dp(6);
        left.addView(pickKey, pickLp);
        EditText label = field(left, "Label (shown with the text icon)", c.label, false);

        Spinner icon = spinner(right, "Icon", TouchOverlay.ICON_NAMES, indexOf(TouchOverlay.ICON_NAMES, c.icon));
        Spinner mode = spinner(right, "Press mode", MODE_LABELS, indexOf(MODE_VALUES, c.mode));
        Spinner show = spinner(right, "Visible in", SHOW_LABELS, indexOf(SHOW_VALUES, c.show));
        CheckBox looks = checkbox(right, "Drag while held turns the view", c.looks);
        CheckBox visible = checkbox(right, "Visible", c.visible);

        ScrollView scroll = new ScrollView(activity);
        scroll.addView(columns);
        dialog()
            .setTitle(c.custom ? "Custom button" : "Button: " + c.id)
            .setView(scroll)
            .setPositiveButton("OK", (d, w) -> {
                c.label = label.getText().toString().trim();
                c.icon = TouchOverlay.ICON_NAMES[icon.getSelectedItemPosition()];
                c.type = TYPE_VALUES[type.getSelectedItemPosition()];
                c.action = action.getText().toString().trim();
                c.mode = MODE_VALUES[mode.getSelectedItemPosition()];
                c.show = SHOW_VALUES[show.getSelectedItemPosition()];
                c.looks = looks.isChecked();
                c.visible = visible.isChecked();
                overlay.refresh();
                onSelectionChanged(c);
            })
            .setNegativeButton("Cancel", null)
            .show();
    }

    private static String[] keyNames;

    private static String[] keyNames() {
        if (keyNames == null) {
            List<String> keys = new ArrayList<>();
            String[] named = { "MOUSE1", "MOUSE2", "MOUSE3", "MWHEELUP", "MWHEELDOWN", "SPACE", "ENTER", "ESCAPE", "TAB",
                "BACKQUOTE", "SHIFT", "CTRL", "ALT", "UPARROW", "DOWNARROW", "LEFTARROW", "RIGHTARROW", "BACKSPACE" };
            for (String k : named) {
                keys.add(k);
            }
            for (char ch = '0'; ch <= '9'; ch++) {
                keys.add(String.valueOf(ch));
            }
            for (char ch = 'a'; ch <= 'z'; ch++) {
                keys.add(String.valueOf(ch));
            }
            for (int f = 1; f <= 12; f++) {
                keys.add("F" + f);
            }
            keyNames = keys.toArray(new String[0]);
        }
        return keyNames;
    }

    private AlertDialog.Builder dialog() {
        return new AlertDialog.Builder(activity, UiStyle.DIALOG_THEME);
    }

    private Button barButton(String text, View.OnClickListener onClick) {
        return barButton(text, UiStyle.Kind.SECONDARY, onClick);
    }

    private Button barButton(String text, UiStyle.Kind kind, View.OnClickListener onClick) {
        Button b = UiStyle.chip(activity, text, kind, onClick);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        lp.setMargins(dp(3), 0, dp(3), 0);
        b.setLayoutParams(lp);
        return b;
    }

    private LinearLayout column() {
        LinearLayout box = new LinearLayout(activity);
        box.setOrientation(LinearLayout.VERTICAL);
        box.setPadding(dp(20), dp(8), dp(20), dp(8));
        return box;
    }

    private TextView caption(LinearLayout box, String text) {
        TextView t = new TextView(activity);
        t.setText(text);
        t.setTextColor(UiStyle.TEXT_DIM);
        t.setTextSize(13);
        t.setPadding(0, dp(12), 0, dp(4));
        box.addView(t);
        return t;
    }

    private EditText field(LinearLayout box, String captionText, String value, boolean numeric) {
        caption(box, captionText);
        EditText e = new EditText(activity);
        e.setSingleLine(true);
        e.setText(value);
        e.setInputType(numeric ? InputType.TYPE_CLASS_NUMBER : InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS);
        UiStyle.field(e);
        box.addView(e);
        return e;
    }

    private Spinner spinner(LinearLayout box, String captionText, String[] items, int selection) {
        caption(box, captionText);
        Spinner s = new Spinner(activity, Spinner.MODE_DROPDOWN);
        s.setAdapter(new ArrayAdapter<>(activity, android.R.layout.simple_spinner_dropdown_item, items));
        UiStyle.spinner(s);
        s.setSelection(Math.max(0, selection));
        box.addView(s);
        return s;
    }

    private CheckBox checkbox(LinearLayout box, String text, boolean checked) {
        CheckBox cb = new CheckBox(activity);
        cb.setText(text);
        cb.setChecked(checked);
        UiStyle.tint(cb);
        box.addView(cb);
        return cb;
    }

    private SeekBar slider(LinearLayout box, String captionText, int min, int max, int value, String unit) {
        TextView t = caption(box, captionText + ": " + value + unit);
        SeekBar bar = new SeekBar(activity);
        bar.setMax(max - min);
        bar.setProgress(Math.max(0, Math.min(max - min, value - min)));
        UiStyle.tint(bar);
        bar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                t.setText(captionText + ": " + (progress + min) + unit);
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {
            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {
            }
        });
        box.addView(bar);
        return bar;
    }

    private static int indexOf(String[] values, String value) {
        for (int i = 0; i < values.length; i++) {
            if (values[i].equals(value)) {
                return i;
            }
        }
        return 0;
    }

    private int dp(int v) {
        return Math.round(v * density);
    }
}
