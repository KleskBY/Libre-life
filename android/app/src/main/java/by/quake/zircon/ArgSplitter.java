package by.quake.zircon;

import java.util.ArrayList;
import java.util.List;

/** Splits a command line typed by the player; double quotes group words, like a desktop shell. */
final class ArgSplitter {

    private ArgSplitter() {
    }

    static List<String> split(String line) {
        List<String> out = new ArrayList<>();
        if (line == null) {
            return out;
        }
        StringBuilder cur = new StringBuilder();
        boolean quoted = false, inToken = false;
        for (int i = 0; i < line.length(); i++) {
            char c = line.charAt(i);
            if (c == '"') {
                quoted = !quoted;
                inToken = true;
            } else if (Character.isWhitespace(c) && !quoted) {
                if (inToken) {
                    out.add(cur.toString());
                    cur.setLength(0);
                    inToken = false;
                }
            } else {
                cur.append(c);
                inToken = true;
            }
        }
        if (inToken) {
            out.add(cur.toString());
        }
        return out;
    }
}
