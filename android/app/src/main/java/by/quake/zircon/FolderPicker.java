package by.quake.zircon;

import android.app.Activity;
import android.app.AlertDialog;
import android.graphics.Color;
import android.os.Environment;
import android.text.InputType;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import java.io.File;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * Picks the folder that holds the game data. Browses real paths rather than using the
 * system document picker: the engine opens files by path, and the app already holds
 * all-files access, so a content URI would have to be copied before it could be read.
 */
final class FolderPicker {

    interface OnPicked {
        void picked(String path);
    }

    private final Activity activity;
    private final String gameDirName;
    private final OnPicked callback;
    private final float density;

    private File current;
    private LinearLayout list;
    private TextView header;
    private TextView status;
    private EditText manual;

    private FolderPicker(Activity activity, String gameDirName, OnPicked callback) {
        this.activity = activity;
        this.gameDirName = gameDirName;
        this.callback = callback;
        this.density = activity.getResources().getDisplayMetrics().density;
    }

    static void show(Activity activity, String startPath, String gameDirName, OnPicked callback) {
        new FolderPicker(activity, gameDirName, callback).open(startPath);
    }

    private void open(String startPath) {
        current = new File(startPath);
        while (current != null && !current.isDirectory()) {
            current = current.getParentFile();
        }
        if (current == null) {
            current = Environment.getExternalStorageDirectory();
        }

        LinearLayout box = new LinearLayout(activity);
        box.setOrientation(LinearLayout.VERTICAL);
        box.setPadding(dp(18), dp(6), dp(18), 0);

        header = new TextView(activity);
        header.setTextColor(UiStyle.TEXT);
        header.setTextSize(13);
        box.addView(header);

        status = new TextView(activity);
        status.setTextColor(UiStyle.TEXT_DIM);
        status.setTextSize(12);
        status.setPadding(0, dp(2), 0, dp(6));
        box.addView(status);

        LinearLayout shortcuts = new LinearLayout(activity);
        shortcuts.setOrientation(LinearLayout.HORIZONTAL);
        for (File f : shortcutFolders()) {
            String label = f.equals(Environment.getExternalStorageDirectory()) ? "Storage"
                : (f.getName().isEmpty() ? f.getAbsolutePath() : f.getName());
            Button b = UiStyle.chip(activity, label, UiStyle.Kind.GHOST, v -> navigate(f));
            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
            lp.rightMargin = dp(6);
            shortcuts.addView(b, lp);
        }
        ScrollView shortcutScroll = new ScrollView(activity);
        LinearLayout shortcutRow = new LinearLayout(activity);
        shortcutRow.addView(shortcuts);
        shortcutScroll.addView(shortcutRow);
        box.addView(shortcutScroll);

        list = new LinearLayout(activity);
        list.setOrientation(LinearLayout.VERTICAL);
        ScrollView scroll = new ScrollView(activity);
        scroll.addView(list);
        box.addView(scroll, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(220)));

        TextView manualLabel = new TextView(activity);
        manualLabel.setText("Or type a path");
        manualLabel.setTextColor(UiStyle.TEXT_DIM);
        manualLabel.setTextSize(12);
        manualLabel.setPadding(0, dp(8), 0, dp(2));
        box.addView(manualLabel);

        manual = new EditText(activity);
        manual.setSingleLine(true);
        manual.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS);
        UiStyle.field(manual);
        box.addView(manual);

        refresh();

        new AlertDialog.Builder(activity, UiStyle.DIALOG_THEME)
            .setTitle("Game folder")
            .setView(box)
            .setPositiveButton("Use this folder", (d, w) -> {
                String typed = manual.getText().toString().trim();
                callback.picked(typed.isEmpty() ? current.getAbsolutePath() : typed);
            })
            .setNegativeButton("Cancel", null)
            .show();
    }

    private List<File> shortcutFolders() {
        Set<File> out = new LinkedHashSet<>();
        File sdcard = Environment.getExternalStorageDirectory();
        out.add(sdcard);
        out.add(new File(sdcard, "Download"));
        File app = activity.getExternalFilesDir(null);
        if (app != null) {
            out.add(app);
        }
        List<File> real = new ArrayList<>();
        for (File f : out) {
            if (f != null && f.isDirectory()) {
                real.add(f);
            }
        }
        return real;
    }

    private void navigate(File dir) {
        if (dir != null && dir.isDirectory()) {
            current = dir;
            refresh();
        }
    }

    private void refresh() {
        header.setText(current.getAbsolutePath());
        manual.setText(current.getAbsolutePath());
        boolean hasData = ModScanner.hasBaseData(current, gameDirName);
        status.setText(hasData
            ? "Game data found in " + gameDirName
            : "No " + gameDirName + " data here; pick the folder that contains " + gameDirName);
        status.setTextColor(hasData ? UiStyle.TEXT_DIM : UiStyle.WARNING);

        list.removeAllViews();
        File parent = current.getParentFile();
        if (parent != null && parent.isDirectory()) {
            list.addView(row(".. (" + parent.getName() + ")", false, v -> navigate(parent)));
        }
        File[] children = current.listFiles(File::isDirectory);
        if (children == null) {
            list.addView(label("Cannot read this folder"));
            return;
        }
        Arrays.sort(children, (a, b) -> a.getName().compareToIgnoreCase(b.getName()));
        int shown = 0;
        for (File child : children) {
            // hidden folders are listed too: players do keep game data in dot-directories
            boolean marked = ModScanner.hasBaseData(child, gameDirName);
            list.addView(row(child.getName() + (marked ? "   game data" : ""), marked, v -> navigate(child)));
            shown++;
        }
        if (shown == 0) {
            list.addView(label("No subfolders"));
        }
    }

    private TextView label(String text) {
        TextView t = new TextView(activity);
        t.setText(text);
        t.setTextColor(UiStyle.TEXT_DIM);
        t.setPadding(dp(4), dp(10), dp(4), dp(10));
        return t;
    }

    private View row(String text, boolean highlight, View.OnClickListener onClick) {
        TextView t = new TextView(activity);
        t.setText(text);
        t.setTextColor(highlight ? UiStyle.accent() : UiStyle.TEXT);
        t.setTextSize(15);
        t.setGravity(Gravity.CENTER_VERTICAL);
        t.setPadding(dp(6), dp(11), dp(6), dp(11));
        t.setBackgroundColor(Color.TRANSPARENT);
        t.setOnClickListener(onClick);
        return t;
    }

    private int dp(int v) {
        return Math.round(v * density);
    }
}
