package by.quake.zircon;

import android.content.Context;
import android.os.Environment;

import java.io.File;

/**
 * Everything that differs between games built from this project. Each product flavor
 * provides FlavorProfile under src/&lt;flavor&gt;/java; shared code only talks to this class.
 */
public abstract class GameProfile {

    public enum DataMode {
        /** game data ships inside the APK as a pk3 and is installed into internal storage */
        BUNDLED_PK3,
        /** the player supplies game data and mods in a shared storage folder */
        EXTERNAL_DIR
    }

    private static GameProfile instance;

    public static GameProfile get() {
        if (instance == null) {
            instance = new FlavorProfile();
        }
        return instance;
    }

    public abstract DataMode dataMode();

    /** base game directory inside the base folder, e.g. "id1" */
    public abstract String baseGameDir();

    /** name shown for the base game in the mod list */
    public abstract String baseGameTitle();

    /** asset path of the default on-screen control layout */
    public abstract String defaultLayoutAsset();

    /** what to tell the player when the base game directory has no data */
    public String dataHint() {
        return "Copy the " + baseGameDir() + " folder of " + baseGameTitle() + " into";
    }

    /** accent for launcher buttons and highlights */
    public int accentColor() {
        return 0xFFE8913A;
    }

    /** pk3 asset installed for BUNDLED_PK3, otherwise null */
    public String bundledPack() {
        return null;
    }

    /** config shipped inside the game data and exec'd first, otherwise null */
    public String builtinCfg() {
        return null;
    }

    /** asset copied into the base game directory before every launch and exec'd first, otherwise null */
    public String defaultsCfgAsset() {
        return null;
    }

    /**
     * Base folder used until the player picks another one. The value comes from the
     * per-flavor string resource default_game_folder, so it is configurable at build time
     * (-Pzircon.gameFolder=...). Relative values resolve against shared storage.
     */
    public String defaultBaseFolder(Context context) {
        String configured = context.getString(R.string.default_game_folder).trim();
        if (configured.isEmpty()) {
            return context.getFilesDir().getAbsolutePath();
        }
        File dir = new File(configured);
        return dir.isAbsolute() ? dir.getAbsolutePath()
            : new File(Environment.getExternalStorageDirectory(), configured).getAbsolutePath();
    }

    public boolean usesExternalStorage() {
        return dataMode() == DataMode.EXTERNAL_DIR;
    }
}
