package by.quake.zircon;

import android.content.Context;
import android.content.SharedPreferences;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.util.Locale;

/** Player-facing engine options, stored in preferences and handed to the engine as a cfg file. */
final class EngineSettings {

    static final String CFG_NAME = "android_settings.cfg";
    private static final String PREFS = "engine_settings";

    static final int[] FPS_CHOICES = { 0, 30, 45, 60, 90, 120 };

    float viewScale;
    int maxFps;
    boolean vsync;
    float lookSensitivity;
    boolean invertLook;
    boolean showFps;
    boolean hideOnGamepad;

    static EngineSettings load(Context context) {
        SharedPreferences p = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
        EngineSettings s = new EngineSettings();
        s.viewScale = p.getFloat("viewScale", 0.7f);
        s.maxFps = p.getInt("maxFps", 0);
        s.vsync = p.getBoolean("vsync", true);
        s.lookSensitivity = p.getFloat("lookSensitivity", 0.3f);
        s.invertLook = p.getBoolean("invertLook", false);
        s.showFps = p.getBoolean("showFps", false);
        s.hideOnGamepad = p.getBoolean("hideOnGamepad", true);
        return s;
    }

    void save(Context context) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putFloat("viewScale", viewScale)
            .putInt("maxFps", maxFps)
            .putBoolean("vsync", vsync)
            .putFloat("lookSensitivity", lookSensitivity)
            .putBoolean("invertLook", invertLook)
            .putBoolean("showFps", showFps)
            .putBoolean("hideOnGamepad", hideOnGamepad)
            .apply();
    }

    String toCfg() {
        return String.format(Locale.US,
            "// written by the launcher on every start; change these in the app's Settings screen\n"
                + "mobile_viewscale %.2f\n"
                + "r_viewscale %.2f\n"
                + "cl_maxfps %d\n"
                + "vid_vsync %d\n"
                + "touch_look_sensitivity %.2f\n"
                + "touch_look_invert %d\n"
                + "showfps %d\n",
            viewScale, viewScale, maxFps, vsync ? 1 : 0, lookSensitivity, invertLook ? 1 : 0, showFps ? 1 : 0);
    }

    void writeCfg(File file) throws IOException {
        try (OutputStream out = new FileOutputStream(file)) {
            out.write(toCfg().getBytes(StandardCharsets.UTF_8));
        }
    }
}
