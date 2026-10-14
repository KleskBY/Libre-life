package by.quake.zircon;

import android.content.Context;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

/**
 * On-screen control layout: button positions, sizes and what each button does.
 * Defaults come from the flavor's asset; edits are saved per game directory in internal storage.
 */
final class ControlLayout {

    static final String TYPE_KEY = "key";
    static final String TYPE_COMMAND = "command";
    static final String TYPE_KEYBOARD = "keyboard";

    static final String MODE_HOLD = "hold";
    static final String MODE_TOGGLE = "toggle";
    static final String MODE_TAP = "tap";

    static final String SHOW_GAME = "game";
    static final String SHOW_CONSOLE = "console";
    static final String SHOW_BOTH = "both";

    static final class Control {
        String id = "";
        String icon = "text";
        String label = "";
        String type = TYPE_KEY;
        String action = "";
        String mode = MODE_HOLD;
        String show = SHOW_GAME;
        boolean looks;
        boolean visible = true;
        boolean custom;
        float x = 0.5f, y = 0.5f; // center, as fractions of the safe area
        float size = 26; // radius in dp before the layout scale

        // runtime state, not saved
        float cx, cy, r;
        boolean down;

        Control copy() {
            Control c = new Control();
            c.id = id;
            c.icon = icon;
            c.label = label;
            c.type = type;
            c.action = action;
            c.mode = mode;
            c.show = show;
            c.looks = looks;
            c.visible = visible;
            c.custom = custom;
            c.x = x;
            c.y = y;
            c.size = size;
            return c;
        }

        JSONObject toJson() throws JSONException {
            JSONObject o = new JSONObject();
            o.put("id", id);
            o.put("icon", icon);
            o.put("label", label);
            o.put("type", type);
            o.put("action", action);
            o.put("mode", mode);
            o.put("show", show);
            o.put("looks", looks);
            o.put("visible", visible);
            o.put("custom", custom);
            o.put("x", (double) x);
            o.put("y", (double) y);
            o.put("size", (double) size);
            return o;
        }

        static Control fromJson(JSONObject o) {
            Control c = new Control();
            c.id = o.optString("id", "");
            c.icon = o.optString("icon", "text");
            c.label = o.optString("label", "");
            c.type = o.optString("type", TYPE_KEY);
            c.action = o.optString("action", "");
            c.mode = o.optString("mode", MODE_HOLD);
            c.show = o.optString("show", SHOW_GAME);
            c.looks = o.optBoolean("looks", false);
            c.visible = o.optBoolean("visible", true);
            c.custom = o.optBoolean("custom", false);
            c.x = (float) o.optDouble("x", 0.5);
            c.y = (float) o.optDouble("y", 0.5);
            c.size = (float) o.optDouble("size", 26);
            return c;
        }
    }

    float opacity = 1f;
    float scale = 1f;
    float stickZone = 0.45f; // fingers landing left of this fraction of the width drive the move stick
    final List<Control> controls = new ArrayList<>();

    ControlLayout copy() {
        ControlLayout l = new ControlLayout();
        l.opacity = opacity;
        l.scale = scale;
        l.stickZone = stickZone;
        for (Control c : controls) {
            l.controls.add(c.copy());
        }
        return l;
    }

    Control find(String id) {
        for (Control c : controls) {
            if (c.id.equals(id)) {
                return c;
            }
        }
        return null;
    }

    static ControlLayout parse(String json) throws JSONException {
        JSONObject root = new JSONObject(json);
        ControlLayout l = new ControlLayout();
        l.opacity = (float) root.optDouble("opacity", 1);
        l.scale = (float) root.optDouble("scale", 1);
        l.stickZone = (float) root.optDouble("stickZone", 0.45);
        JSONArray arr = root.optJSONArray("controls");
        if (arr != null) {
            for (int i = 0; i < arr.length(); i++) {
                l.controls.add(Control.fromJson(arr.getJSONObject(i)));
            }
        }
        return l;
    }

    String toJson() throws JSONException {
        JSONObject root = new JSONObject();
        root.put("version", 1);
        root.put("opacity", (double) opacity);
        root.put("scale", (double) scale);
        root.put("stickZone", (double) stickZone);
        JSONArray arr = new JSONArray();
        for (Control c : controls) {
            arr.put(c.toJson());
        }
        root.put("controls", arr);
        return root.toString(2);
    }

    static ControlLayout loadDefault(Context context) {
        try (InputStream in = context.getAssets().open(GameProfile.get().defaultLayoutAsset())) {
            return parse(new String(in.readAllBytes(), StandardCharsets.UTF_8));
        } catch (IOException | JSONException e) {
            throw new IllegalStateException("default control layout is missing or invalid", e);
        }
    }

    /** saved layout for this game directory, else the base game's saved layout, else the flavor default */
    static ControlLayout load(Context context, String gameDir) {
        String[] keys = { gameDir, GameProfile.get().baseGameDir() };
        for (String key : keys) {
            File f = file(context, key);
            if (f.isFile()) {
                try (InputStream in = new FileInputStream(f)) {
                    return parse(new String(in.readAllBytes(), StandardCharsets.UTF_8));
                } catch (IOException | JSONException ignored) {
                    // a broken saved layout falls back to the next candidate
                }
            }
        }
        return loadDefault(context);
    }

    void save(Context context, String gameDir) throws IOException {
        File f = file(context, gameDir);
        f.getParentFile().mkdirs();
        try (OutputStream out = new FileOutputStream(f)) {
            out.write(toJson().getBytes(StandardCharsets.UTF_8));
        } catch (JSONException e) {
            throw new IOException(e);
        }
    }

    static void deleteAllSaved(Context context) {
        File[] files = new File(context.getFilesDir(), "controls").listFiles();
        if (files != null) {
            for (File f : files) {
                f.delete();
            }
        }
    }

    private static File file(Context context, String gameDir) {
        String safe = gameDir.replaceAll("[^A-Za-z0-9._-]", "_");
        return new File(new File(context.getFilesDir(), "controls"), safe + ".json");
    }
}
