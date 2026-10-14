"""Verify that every Android port change is present in an engine tree.

Run after upgrading the Zircon engine (see ENGINE_UPGRADE.md). A merge can silently
drop a hunk; this catches that before the build or, worse, before a device test.

    python tools/check_android_patches.py [engine_dir]

Exit code 0 = all patches found, 1 = something is missing.
"""

import os
import sys

# (file, marker, what it does)
ENGINE_PATCHES = [
    ("vid_sdl.c", "Android_Touch_Frame", "touch bridge called from Sys_SendKeyEvents"),
    ("vid_sdl.c", "Android_Touch_Move", "analog move/look applied in IN_Move"),
    ("vid_sdl.c", "Android_Touch_CursorOverride", "touch cursor overrides in_windowmouse"),
    ("vid_sdl.c", "SDL_GL_GetDrawableSize", "real drawable size, else the view is cropped"),
    ("cl_input.c", "android_touch_cursor_ui", "no mouse look while game code owns the pointer"),
    ("clvm_cmds.c", "android_csqc_cursor_time", "VM_drawpic notes the game's own cursor"),
    ("console.c", "ANDROID_TOUCH_OVERLAY", "no forced log file on Android"),
    ("gl_backend.c", "Android_ShaderCache_Load", "GLSL program binary cache"),
    ("gl_backend.c", "Android_ShaderCache_Save", "GLSL program binary cache"),
    ("gl_textures.c", "GL_UNSIGNED_INT_24_8", "GLES depth/stencil formats for the view FBO"),
    ("vid_shared.c", "!defined(__ANDROID__)", "cubemap size query ungated (flashlight)"),
    ("fs.c", "S_ISDIR", "directories must not open as files (hud.ttf vs gfx/hud)"),
    ("filematch_stringlist.c.h", "fullpath[0] != '/'", "pk3 listing inside internal storage"),
    ("model_alias.c", "frameskip", "MD3 frame thinning sidecar"),
    ("model_shared.h", "frameskip", "MD3 frame thinning field"),
    ("prvm_cmds.c", "frameskip", "pose blending for thinned MD3 models"),
    ("lhnet.h", "LHNETADDRESSTYPE_STEAM_FAKEIP", "enum needed by cl_main.c in non-Steam builds"),
    ("lhnet.c", "#undef modulo", "baker.h macro collides with NDK linux/hdlc/ioctl.h"),
]

# files of ours that live in the Android project, not the engine tree
PROJECT_FILES = [
    ("app/src/main/cpp/touch_android.c", "Android_Touch_Frame"),
    ("app/src/main/cpp/shader_cache_android.c", "Android_ShaderCache_Save"),
    ("app/src/main/cpp/steam_android.c", "NetConn_DropSteamConnection"),
    ("app/src/main/cpp/android_compat.h", "HMODULE"),
]


def check(root, items, label):
    missing = []
    for rel, marker, *rest in items:
        why = rest[0] if rest else ""
        path = os.path.join(root, rel)
        try:
            with open(path, "r", encoding="utf-8", errors="replace") as f:
                found = marker in f.read()
        except OSError:
            found = False
            why = (why + " [file not found]").strip()
        if not found:
            missing.append((rel, marker, why))
        print(("  OK   " if found else "  MISS ") + f"{rel:28} {marker}")
    if missing:
        print(f"\n{label}: {len(missing)} patch(es) missing:")
        for rel, marker, why in missing:
            print(f"  {rel}: {marker}  <- {why}")
    return missing


def main():
    here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # android/
    engine = (sys.argv[1] if len(sys.argv) > 1 else
              os.environ.get("ZIRCON_ENGINE_DIR") or os.path.join(here, "..", "engine_source"))
    engine = os.path.abspath(engine)
    print(f"engine tree:  {engine}")
    print(f"project tree: {here}\n")
    missing = check(engine, ENGINE_PATCHES, "engine")
    print()
    missing += check(here, PROJECT_FILES, "project")
    if missing:
        print("\nFAILED: re-apply the missing hunks (git log in engine_upgrade shows them).")
        return 1
    print("\nAll Android patches present.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
