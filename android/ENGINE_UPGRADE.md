# Engine upgrade guide

How to move the Android port onto a newer Zircon engine without losing the port.

**Current state:** `engine_source` (whatever ZIRCON_ENGINE_DIR / zircon.engineDir points at) is **Zircon Beta 164** (upstream dump `zircon_beta_engine_source_20260829`),
upgraded from Beta 106 on 2026-09-17. The previous tree is kept at `engine_source_beta106`.

Zircon is a DarkPlaces fork; releases arrive as a full source dump (a folder, no git history),
so the upgrade is a 3-way merge between the old release, the new release, and our tree.

## Layout

| Path | What it is |
| --- | --- |
| `engine_source/` | the engine we compile: newest Zircon + our patches |
| `engine_source_beta<N>/` | previous engine, kept for comparison and rollback |
| `engine_upgrade/` | git workspace with branches `base`, `upstream`, `android` |
| `android/tools/engine_upgrade.py` | import / merge / export automation |
| `android/tools/check_android_patches.py` | verifies every patch is still present |
| `android/app/src/main/cpp/` | our own sources (`touch_android.c`, `shader_cache_android.c`, `steam_android.c`, `android_compat.h`); upstream never touches these |

The workspace branches:

- **base** — pristine Zircon release the port started from.
- **upstream** — pristine newer releases, one commit per dump, always branching from the previous upstream commit.
- **android** — what we ship: base + ObjectN Steam/net customizations + the Android port.

## What our patches are

Engine files we modify. Keep this list in sync with `check_android_patches.py`.

| File | Change |
| --- | --- |
| `vid_sdl.c` | touch bridge hooks (`Android_Touch_Frame` in `Sys_SendKeyEvents`, `Android_Touch_Move` in `IN_Move`, cursor override), real drawable size, no forced `vid_touchscreen` |
| `cl_input.c` | skip mouse-look while game code owns the pointer (`android_touch_cursor_ui`) |
| `clvm_cmds.c` | `VM_drawpic` records when game code draws its own cursor (`android_csqc_cursor_time`) |
| `console.c` | no forced `zircon_log.log` on Android |
| `gl_backend.c` | GLSL program binary cache hooks |
| `gl_rmain.c` | ObjectN shader warm-up permutation list |
| `gl_textures.c` | GLES depth/stencil/color formats for the view FBO |
| `vid_shared.c` | cubemap size query not gated behind the desktop extension check (flashlight) |
| `fs.c` | reject directories in `FS_SysOpen` (a `gfx/hud` folder shadowed `hud.ttf`) |
| `filematch_stringlist.c.h` | pk3 listing for internal storage paths |
| `model_alias.c`, `model_shared.h`, `prvm_cmds.c` | MD3 frame thinning (`.frameskip` sidecar) and pose blending |
| `sys.h` | no `USE_RWOPS`, no XMP on Android |
| `lhnet.h`, `lhnet.c` | upstream quirks, see below |

Everything else lives in the Android project and is never merged.

## Upgrade procedure

Prerequisites: Python 3, git, the NDK/Gradle setup that already builds the port, phone on USB.

### 1. Import the new dump

```bash
cd <repo>/android
python tools/engine_upgrade.py import "<path to the new dump>"
```

This commits the dump on the `upstream` branch (normalized to LF first — the dumps mix CRLF
and LF per file, and without normalizing every file looks fully rewritten and every merge conflicts).

### 2. Merge

```bash
python tools/engine_upgrade.py merge --auto-upstream
```

`--auto-upstream` resolves the known Steam/net files to upstream (Beta 164 absorbed the
ObjectN `KLESKBY_STEAM` extension and moved `kleskby/steam*.c` to top-level `steam.c` / `steam_net.c`).
Anything else conflicting is listed as `MANUAL`.

**Conflict policy**

- Steam/network plumbing (`lhnet*`, `netconn*`, `svvm_cmds*`, `prvm_steam.h`, `sys_sdl.c`, `steam*`): take upstream.
- Files carrying Android hunks: keep **both** sides — upstream's new code plus our hunk.
  Search the conflict for `ANDROID_TOUCH_OVERLAY`, `android_touch_cursor_ui`,
  `android_csqc_cursor_time`, `frameskip`.
- Files upstream deleted that we modified: usually accept the deletion, then check whether
  the Android build still needs the symbols (see step 4).

Finish a manual resolution with:

```bash
git -C ../engine_upgrade add <files>
git -C ../engine_upgrade commit
```

### 3. Verify the patches survived

```bash
python tools/check_android_patches.py ../engine_upgrade
```

Every line must read `OK`. A `MISS` means the merge dropped a hunk; re-apply it in the
workspace before going further (`git -C ../engine_upgrade log -p` shows the original).

### 4. Build against the candidate tree without promoting it

```bash
./gradlew.bat assembleQuakeDebug assembleObjectnDebug -Pandroid.injected.build.abi=arm64-v8a -Pzircon.engineDir=<workspace>
```

`zircon.engineDir` points CMake at any engine tree, so the shipping `engine_source` (whatever ZIRCON_ENGINE_DIR / zircon.engineDir points at) stays
untouched until the candidate works. The CMake source list skips engine files that no longer
exist, so an upstream file move is a log line, not a configure error.

Fix build errors in the workspace tree, then re-run `check_android_patches.py`.

### 5. Test on the phone

Install both flavors and check:

- Quake: launcher lists mods, `Play` starts id1, controls draw, frame stats appear in
  `adb logcat | grep ObjectNTouch`.
- ObjectN: data installs, game starts, touch controls work.
- Cursor UI: `map lobby` via the debug hook, state becomes `9` (in game + cursor UI),
  taps drive the game cursor, ESC/console buttons remain.
- Long-press the menu button: the control editor opens, save/reset work.
- Settings: an fps limit reaches the engine (median frame time changes).

Debug hook (runs one console line, then deletes it):

```bash
printf 'map lobby\n' > %TEMP%/android_cmd.cfg
adb push %TEMP%/android_cmd.cfg /data/local/tmp/android_cmd.cfg
adb shell "run-as by.quake.zircon cp /data/local/tmp/android_cmd.cfg files/data/android_cmd.cfg"
```

### 6. Promote

```bash
python tools/engine_upgrade.py export
```

Moves the old `engine_source` (whatever ZIRCON_ENGINE_DIR / zircon.engineDir points at) to `engine_source_beta<old>` and writes the merged tree to
`engine_source` (whatever ZIRCON_ENGINE_DIR / zircon.engineDir points at), so normal builds (no `-P` flag) use it. Re-run `check_android_patches.py`
and build once more without the flag.

### Rollback

```bash
rm -rf engine_source && mv engine_source_beta106 engine_source     # or whichever backup
```

The workspace keeps every state: `git -C engine_upgrade log --graph --all`.

## Known upstream quirks

Baker builds Zircon with Steam enabled, so non-Steam builds hit these. Both are already applied:

1. `lhnet.h` declared `LHNETADDRESSTYPE_STEAM_FAKEIP` inside `#ifdef STEAM_NETWORKING`, but
   `cl_main.c` uses it unconditionally. The enum value is now always declared.
2. `netconn.c` defines `NetConn_DropSteamConnection` under `STEAM_NETWORKING` but calls it
   unconditionally from a console command. Stubbed in `steam_android.c`.
3. `baker.h` defines `modulo` as `%`, which collides with a struct member in the NDK's
   `linux/hdlc/ioctl.h` that `lhnet.c` pulls in. `lhnet.c` undefines it on Android.

If a future release fixes these upstream, the merge will show them as conflicts; take upstream.

## Notes

- Do not edit `engine_source` (whatever ZIRCON_ENGINE_DIR / zircon.engineDir points at) for Android work without recording it here and in
  `check_android_patches.py`, or the next upgrade will silently lose it.
- The workspace normalizes to LF. The exported tree is LF too; MSVC and the NDK both accept it.
- `third_party/` (SDL2, libjpeg-turbo, ogg/vorbis, freetype) is independent of the engine version.
- The periodic ~45 ms frame stalls are a GPU/driver issue on the test device, not an engine
  version issue; they persist across Beta 106 and 164.
