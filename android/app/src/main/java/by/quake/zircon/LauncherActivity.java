package by.quake.zircon;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.res.AssetManager;
import android.graphics.Color;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AbsListView;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.ProgressBar;
import android.widget.ScrollView;
import android.widget.TextView;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * Entry screen. Bundled games install their pk3 into internal storage and offer Play, Controls
 * and Settings. External-data games also ask for storage access and list the mods found in the
 * player's game folder, each with its own extra command line.
 */
public class LauncherActivity extends Activity {

    static final String EXTRA_BASEDIR = "basedir";
    static final String EXTRA_GAMEDIR = "gamedir";
    static final String EXTRA_ARGS = "args";
    static final String EXTRA_EDIT_CONTROLS = "editControls";

    static final String PREFS = "launcher";
    private static final String PREF_BASE_FOLDER = "baseFolder";
    private static final String PREF_LAST_MOD = "lastMod";
    private static final String PREF_ARGS = "args.";

    private static final int REQUEST_STORAGE = 1;

    private final Handler ui = new Handler(Looper.getMainLooper());
    private final GameProfile profile = GameProfile.get();
    private SharedPreferences prefs;
    private float density;

    private boolean mainShown;
    private final List<ModScanner.Mod> mods = new ArrayList<>();
    private ArrayAdapter<ModScanner.Mod> modAdapter;
    private ListView modList;
    private ModScanner.Mod selected;
    private TextView modTitle, modDescription, folderText, statusText;
    private EditText argsEdit;
    private Button playButton, controlsButton;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        prefs = getSharedPreferences(PREFS, MODE_PRIVATE);
        density = getResources().getDisplayMetrics().density;
        if (!profile.usesExternalStorage()) {
            showInstallProgress();
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (!profile.usesExternalStorage()) {
            return;
        }
        if (!StoragePermission.granted(this)) {
            showPermissionScreen();
        } else if (!mainShown) {
            showModBrowser();
        } else {
            refreshMods();
        }
    }

    @Override
    protected void onPause() {
        super.onPause();
        saveArgs();
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == REQUEST_STORAGE && StoragePermission.granted(this)) {
            showModBrowser();
        }
    }

    // bundled data

    private void showInstallProgress() {
        FrameLayout frame = splashFrame();
        LinearLayout box = bottomBox(frame);
        TextView status = text("Preparing game data…", 14, Color.LTGRAY);
        status.setGravity(Gravity.CENTER);
        box.addView(status);
        ProgressBar progress = new ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal);
        progress.setMax(1000);
        box.addView(progress, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        setContentView(frame);

        new Thread(() -> {
            try {
                installPack(permille -> ui.post(() -> progress.setProgress(permille)));
                ui.post(this::showBundledMenu);
            } catch (IOException e) {
                ui.post(() -> status.setText("Could not install game data: " + e.getMessage()));
            }
        }, "game-install").start();
    }

    private interface Progress {
        void report(int permille);
    }

    private void installPack(Progress progress) throws IOException {
        String pack = profile.bundledPack();
        AssetManager assets = getAssets();
        String version = readAll(assets.open(pack + ".version")).trim();
        File dataDir = new File(getFilesDir(), profile.baseGameDir());
        File stamp = new File(dataDir, pack + ".version");
        File target = new File(dataDir, pack);
        if (target.exists() && stamp.exists() && readAll(new FileInputStream(stamp)).trim().equals(version)) {
            return;
        }
        dataDir.mkdirs();
        File partial = new File(dataDir, pack + ".partial");
        long total = assets.openFd(pack).getLength();
        try (InputStream in = assets.open(pack); OutputStream out = new FileOutputStream(partial)) {
            byte[] buf = new byte[1 << 20];
            long done = 0;
            int n;
            while ((n = in.read(buf)) > 0) {
                out.write(buf, 0, n);
                done += n;
                progress.report((int) (done * 1000 / Math.max(1, total)));
            }
        }
        if (!partial.renameTo(target)) {
            throw new IOException("could not finalize " + target);
        }
        try (OutputStream out = new FileOutputStream(stamp)) {
            out.write(version.getBytes(StandardCharsets.UTF_8));
        }
    }

    private void showBundledMenu() {
        FrameLayout frame = splashFrame();
        LinearLayout box = bottomBox(frame);
        LinearLayout row = new LinearLayout(this);
        row.setGravity(Gravity.CENTER);
        row.addView(button("Play", UiStyle.Kind.PRIMARY, v -> launch(false)));
        row.addView(button("Controls", v -> launch(true)));
        row.addView(button("Settings", v -> startActivity(new Intent(this, SettingsActivity.class))));
        box.addView(row);
        statusText = text("", 13, UiStyle.WARNING);
        statusText.setGravity(Gravity.CENTER);
        box.addView(statusText);
        setContentView(frame);
    }

    // external data

    private void showPermissionScreen() {
        mainShown = false;
        LinearLayout box = new LinearLayout(this);
        box.setOrientation(LinearLayout.VERTICAL);
        box.setGravity(Gravity.CENTER);
        box.setPadding(dp(48), dp(24), dp(48), dp(24));
        box.setBackgroundColor(UiStyle.BG);

        TextView title = text("Storage access needed", 24, Color.WHITE);
        title.setGravity(Gravity.CENTER);
        box.addView(title, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        TextView body = text("", 15, Color.LTGRAY);
        body.setText(profile.baseGameTitle() + " reads your own game files, mods and saves from "
            + baseFolder() + " (the folder other Android Quake ports use).\n\n"
            + "Android shows this as \"All files access\". Turn it on for this app on the next screen, then come back.");
        body.setGravity(Gravity.CENTER);
        body.setPadding(0, dp(12), 0, dp(20));
        box.addView(body);
        box.addView(button("Grant access", UiStyle.Kind.PRIMARY, v -> StoragePermission.request(this, REQUEST_STORAGE)));
        UiStyle.applyInsets(box);
        setContentView(box);
    }

    private void showModBrowser() {
        mainShown = true;
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.HORIZONTAL);
        root.setBackgroundColor(UiStyle.BG);
        root.setPadding(dp(20), dp(16), dp(20), dp(16));

        LinearLayout left = new LinearLayout(this);
        left.setOrientation(LinearLayout.VERTICAL);
        left.addView(text(profile.baseGameTitle(), 26, Color.WHITE));
        folderText = text("", 12, Color.GRAY);
        left.addView(folderText);
        modList = new ListView(this);
        modList.setChoiceMode(AbsListView.CHOICE_MODE_SINGLE);
        UiStyle.list(modList);
        modAdapter = UiStyle.listAdapter(this, mods);
        modList.setAdapter(modAdapter);
        modList.setOnItemClickListener((parent, view, position, id) -> select(mods.get(position)));
        left.addView(modList, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1));
        root.addView(left, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, 0.9f));

        LinearLayout right = new LinearLayout(this);
        right.setOrientation(LinearLayout.VERTICAL);
        right.setBackground(UiStyle.card(this));
        right.setPadding(dp(22), dp(18), dp(22), dp(18));
        modTitle = text("", 22, Color.WHITE);
        right.addView(modTitle);
        modDescription = text("", 13, Color.LTGRAY);
        right.addView(modDescription);
        right.addView(text("Command line", 13, Color.GRAY));
        argsEdit = new EditText(this);
        argsEdit.setSingleLine(true);
        argsEdit.setHint("e.g. +map e1m1 -nosound");
        UiStyle.field(argsEdit);
        right.addView(argsEdit, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        statusText = text("", 13, UiStyle.WARNING);
        right.addView(statusText);

        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setPadding(0, dp(8), 0, 0);
        playButton = button("Play", UiStyle.Kind.PRIMARY, v -> launch(false));
        row.addView(playButton);
        controlsButton = button("Controls", v -> launch(true));
        row.addView(controlsButton);
        right.addView(row);

        LinearLayout row2 = new LinearLayout(this);
        row2.setOrientation(LinearLayout.HORIZONTAL);
        row2.addView(button("Settings", v -> startActivity(new Intent(this, SettingsActivity.class))));
        row2.addView(button("Game folder", v -> showFolderDialog()));
        right.addView(row2);

        // Refresh gets its own row; three pills do not fit the panel width on a phone
        LinearLayout row3 = new LinearLayout(this);
        row3.setOrientation(LinearLayout.HORIZONTAL);
        row3.addView(button("Refresh mod list", UiStyle.Kind.GHOST, v -> refreshMods()));
        right.addView(row3);

        ScrollView rightScroll = new ScrollView(this);
        rightScroll.setVerticalScrollBarEnabled(false);
        rightScroll.addView(right);
        LinearLayout.LayoutParams rightLp = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, 1.1f);
        rightLp.leftMargin = dp(16);
        root.addView(rightScroll, rightLp);

        UiStyle.applyInsets(root);
        setContentView(root);
        refreshMods();
    }

    private String baseFolder() {
        return prefs.getString(PREF_BASE_FOLDER, profile.defaultBaseFolder(this));
    }

    private void refreshMods() {
        if (modAdapter == null) {
            return;
        }
        saveArgs();
        // No mkdirs here: creating the folder tree on every refresh litters storage with empty
        // directories and hides the fact that the configured path does not exist yet.
        File base = new File(baseFolder());
        folderText.setText(base.getAbsolutePath() + (base.isDirectory() ? "" : "   (missing)"));

        mods.clear();
        mods.addAll(ModScanner.scan(base, profile.baseGameDir(), profile.baseGameTitle()));
        modAdapter.notifyDataSetChanged();

        boolean hasData = ModScanner.hasBaseData(base, profile.baseGameDir());
        if (!hasData) {
            statusText.setText("No game data found. " + profile.dataHint() + "\n"
                + new File(base, profile.baseGameDir()).getAbsolutePath());
        } else {
            statusText.setText("");
        }
        playButton.setEnabled(hasData);
        controlsButton.setEnabled(hasData);

        String last = prefs.getString(PREF_LAST_MOD, profile.baseGameDir());
        int index = -1;
        for (int i = 0; i < mods.size(); i++) {
            if (mods.get(i).dir.equals(last)) {
                index = i;
            }
        }
        if (index < 0 && !mods.isEmpty()) {
            index = 0;
        }
        if (index >= 0) {
            modList.setItemChecked(index, true);
            select(mods.get(index));
        } else {
            selected = null;
            modTitle.setText(profile.baseGameTitle());
            modDescription.setText("");
            argsEdit.setText("");
        }
    }

    private void select(ModScanner.Mod mod) {
        if (selected != null && selected != mod) {
            saveArgs();
        }
        selected = mod;
        modTitle.setText(mod.isBase ? mod.title : mod.title);
        modDescription.setText(mod.description.isEmpty() ? (mod.isBase ? "Base game" : "Mod folder: " + mod.dir) : mod.description);
        argsEdit.setText(prefs.getString(PREF_ARGS + mod.dir, ""));
        prefs.edit().putString(PREF_LAST_MOD, mod.dir).apply();
    }

    private void saveArgs() {
        if (selected != null && argsEdit != null) {
            prefs.edit().putString(PREF_ARGS + selected.dir, argsEdit.getText().toString().trim()).apply();
        }
    }

    private void showFolderDialog() {
        FolderPicker.show(this, baseFolder(), profile.baseGameDir(), path -> {
            if (!path.isEmpty()) {
                prefs.edit().putString(PREF_BASE_FOLDER, path).apply();
                refreshMods();
            }
        });
    }

    // launching

    private void launch(boolean editControls) {
        saveArgs();
        String base = profile.usesExternalStorage() ? baseFolder() : getFilesDir().getAbsolutePath();
        String gameDir = selected != null ? selected.dir : profile.baseGameDir();
        String args = selected != null ? prefs.getString(PREF_ARGS + selected.dir, "") : "";
        try {
            writeLaunchConfigs(new File(base, profile.baseGameDir()));
        } catch (IOException e) {
            statusText.setText("Could not write engine settings: " + e.getMessage());
            return;
        }
        Intent intent = new Intent(this, GameActivity.class)
            .putExtra(EXTRA_BASEDIR, base)
            .putExtra(EXTRA_GAMEDIR, gameDir)
            .putExtra(EXTRA_ARGS, args)
            .putExtra(EXTRA_EDIT_CONTROLS, editControls);
        startActivity(intent);
        // the engine cannot restart inside one process; returning here happens through a fresh app start
        finish();
    }

    /** mobile defaults and player settings are rewritten on every launch, so edits here always win */
    private void writeLaunchConfigs(File baseGameDir) throws IOException {
        baseGameDir.mkdirs();
        String defaults = profile.defaultsCfgAsset();
        if (defaults != null) {
            try (InputStream in = getAssets().open(defaults); OutputStream out = new FileOutputStream(new File(baseGameDir, defaults))) {
                out.write(in.readAllBytes());
            }
        }
        EngineSettings.load(this).writeCfg(new File(baseGameDir, EngineSettings.CFG_NAME));
    }

    // views

    private FrameLayout splashFrame() {
        FrameLayout frame = new FrameLayout(this);
        frame.setBackgroundColor(Color.BLACK);
        ImageView splash = new ImageView(this);
        splash.setImageResource(R.drawable.splash);
        splash.setScaleType(ImageView.ScaleType.CENTER_CROP);
        frame.addView(splash, new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        return frame;
    }

    private LinearLayout bottomBox(FrameLayout frame) {
        LinearLayout box = new LinearLayout(this);
        box.setOrientation(LinearLayout.VERTICAL);
        box.setGravity(Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL);
        box.setPadding(dp(48), dp(48), dp(48), dp(24));
        UiStyle.applyInsets(box);
        frame.addView(box, new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        return box;
    }

    private TextView text(String value, int sp, int color) {
        TextView t = new TextView(this);
        t.setText(value);
        t.setTextSize(sp);
        t.setTextColor(color);
        return t;
    }

    private Button button(String label, View.OnClickListener onClick) {
        return button(label, UiStyle.Kind.SECONDARY, onClick);
    }

    private Button button(String label, UiStyle.Kind kind, View.OnClickListener onClick) {
        Button b = UiStyle.button(this, label, kind, onClick);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        lp.setMargins(0, dp(6), dp(10), dp(6));
        b.setLayoutParams(lp);
        return b;
    }

    private int dp(int v) {
        return Math.round(v * density);
    }

    private static String readAll(InputStream in) throws IOException {
        try (InputStream s = in) {
            return new String(s.readAllBytes(), StandardCharsets.UTF_8);
        }
    }
}
