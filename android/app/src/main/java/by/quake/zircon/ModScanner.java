package by.quake.zircon;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

/** Finds game directories (base game and mods) inside a base folder. */
final class ModScanner {

    static final class Mod {
        final String dir;
        final String title;
        final String description;
        final boolean isBase;

        Mod(String dir, String title, String description, boolean isBase) {
            this.dir = dir;
            this.title = title;
            this.description = description;
            this.isBase = isBase;
        }

        @Override
        public String toString() {
            return isBase ? title + "  (" + dir + ")" : title;
        }
    }

    // engine and tool output folders that also contain game-looking files
    private static final Set<String> SKIP = new HashSet<>(Arrays.asList(
        "levelshots", "screenshots", "dlcache", "shadercache", "savegames", "demos", "logs"));

    private static final String[] DESCRIPTION_FILES = { "modinfo.txt", "description.txt" };

    private ModScanner() {
    }

    static List<Mod> scan(File base, String baseGameDir, String baseGameTitle) {
        List<Mod> mods = new ArrayList<>();
        File[] dirs = base.listFiles(File::isDirectory);
        if (dirs == null) {
            return mods;
        }
        Mod baseMod = null;
        for (File dir : dirs) {
            String name = dir.getName();
            if (name.startsWith(".") || SKIP.contains(name.toLowerCase(Locale.ROOT)) || !isGameDir(dir)) {
                continue;
            }
            boolean isBase = name.equals(baseGameDir);
            Mod mod = new Mod(name, isBase ? baseGameTitle : name, describe(dir), isBase);
            if (isBase) {
                baseMod = mod;
            } else {
                mods.add(mod);
            }
        }
        mods.sort((a, b) -> a.title.compareToIgnoreCase(b.title));
        if (baseMod != null) {
            mods.add(0, baseMod);
        }
        return mods;
    }

    /**
     * True when the base game directory holds something the engine can load: a pack, or a
     * loose gamedir. Quake ships paks, Libre-life ships progs.dat plus pk3s, so testing for
     * paks alone would reject a perfectly good folder.
     */
    static boolean hasBaseData(File base, String baseGameDir) {
        return isGameDir(new File(base, baseGameDir));
    }

    static boolean isGameDir(File dir) {
        File[] files = dir.listFiles();
        if (files == null) {
            return false;
        }
        for (File f : files) {
            String n = f.getName().toLowerCase(Locale.ROOT);
            if (f.isDirectory()) {
                if (n.equals("maps") || n.equals("progs") || n.endsWith(".pk3dir")) {
                    return true;
                }
            } else if (n.endsWith(".pak") || n.endsWith(".pk3") || n.equals("progs.dat")
                || n.equals("csprogs.dat") || n.equals("menu.dat") || n.equals("qwprogs.dat")) {
                return true;
            }
        }
        return false;
    }

    private static String describe(File dir) {
        for (String name : DESCRIPTION_FILES) {
            File f = new File(dir, name);
            if (!f.isFile()) {
                continue;
            }
            try (BufferedReader in = new BufferedReader(new InputStreamReader(new FileInputStream(f), StandardCharsets.UTF_8))) {
                String line;
                while ((line = in.readLine()) != null) {
                    line = line.trim();
                    if (!line.isEmpty()) {
                        return line.length() > 160 ? line.substring(0, 160) + "…" : line;
                    }
                }
            } catch (IOException ignored) {
                // unreadable description is not worth reporting
            }
        }
        return "";
    }
}
