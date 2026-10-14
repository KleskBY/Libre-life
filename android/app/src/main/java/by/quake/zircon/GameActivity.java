package by.quake.zircon;

import android.content.Intent;
import android.os.Bundle;
import android.view.InputDevice;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.ViewGroup;

import org.libsdl.app.SDLActivity;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

/** SDL game activity: engine arguments from the launcher, touch controls, control editor, gamepad handling. */
public class GameActivity extends SDLActivity {

    private TouchOverlay overlay;
    private ControlEditor editor;
    private boolean hideOnGamepad;

    @Override
    protected String[] getLibraries() {
        return new String[] { "SDL2", "main" };
    }

    @Override
    protected String[] getArguments() {
        GameProfile profile = GameProfile.get();
        Intent intent = getIntent();
        List<String> args = new ArrayList<>();

        String base = intent.getStringExtra(LauncherActivity.EXTRA_BASEDIR);
        if (base == null || base.isEmpty()) {
            // Internal storage: files there are owned by the app uid. Data adb pushes into
            // Android/data keeps the shell uid and reads back as Permission denied.
            base = profile.usesExternalStorage() ? profile.defaultBaseFolder(this) : getFilesDir().getAbsolutePath();
        }
        new File(base).mkdirs();
        args.add("-basedir");
        args.add(base.endsWith("/") ? base : base + "/");
        if (profile.usesExternalStorage()) {
            args.add("-nohome"); // configs and saves stay next to the game data the player manages
        }

        String gameDir = gameDir();
        if (!gameDir.equals(profile.baseGameDir())) {
            args.add("-game");
            args.add(gameDir);
        }

        if (profile.builtinCfg() != null) {
            args.add("+exec");
            args.add(profile.builtinCfg());
        }
        if (profile.defaultsCfgAsset() != null) {
            args.add("+exec");
            args.add(profile.defaultsCfgAsset());
        }
        args.add("+exec");
        args.add(EngineSettings.CFG_NAME);

        args.addAll(ArgSplitter.split(intent.getStringExtra(LauncherActivity.EXTRA_ARGS)));
        return args.toArray(new String[0]);
    }

    private String gameDir() {
        String dir = getIntent().getStringExtra(LauncherActivity.EXTRA_GAMEDIR);
        return dir == null || dir.isEmpty() ? GameProfile.get().baseGameDir() : dir;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (mLayout == null) {
            return; // SDL failed to load its libraries and is showing its own error dialog
        }
        hideOnGamepad = EngineSettings.load(this).hideOnGamepad;
        overlay = new TouchOverlay(this, ControlLayout.load(this, gameDir()));
        mLayout.addView(overlay, new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        editor = new ControlEditor(this, mLayout, overlay, gameDir());
        if (getIntent().getBooleanExtra(LauncherActivity.EXTRA_EDIT_CONTROLS, false)) {
            overlay.post(editor::open);
        }
    }

    @Override
    public void onBackPressed() {
        if (editor != null && editor.isOpen()) {
            editor.close(false);
            return;
        }
        super.onBackPressed();
    }

    @Override
    public boolean dispatchKeyEvent(KeyEvent event) {
        if (isGamepad(event.getSource())) {
            onGamepadInput();
        }
        return super.dispatchKeyEvent(event);
    }

    @Override
    public boolean dispatchGenericMotionEvent(MotionEvent event) {
        if (isGamepad(event.getSource())) {
            onGamepadInput();
        }
        return super.dispatchGenericMotionEvent(event);
    }

    private static boolean isGamepad(int source) {
        return (source & InputDevice.SOURCE_GAMEPAD) == InputDevice.SOURCE_GAMEPAD
            || (source & InputDevice.SOURCE_JOYSTICK) == InputDevice.SOURCE_JOYSTICK;
    }

    private void onGamepadInput() {
        if (hideOnGamepad && overlay != null) {
            overlay.setGamepadActive(true);
        }
    }

    @Override
    protected void onDestroy() {
        boolean finishing = isFinishing();
        super.onDestroy();
        if (finishing) {
            // The engine keeps global state in its native library and cannot run a second time in
            // this process; the next start from the launcher must get a fresh one.
            System.exit(0);
        }
    }
}
