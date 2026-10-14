# 17 — Android port (Zircon on Android)

The port lives in this repo at [`android/`](../../android). It is a Zircon
Android shell shared by several games on this engine; Libre-life is one product
flavor of it.

Practical references, kept next to the code: [`android/README.md`](../../android/README.md)
for build and properties, [`android/ENGINE_UPGRADE.md`](../../android/ENGINE_UPGRADE.md)
for moving to a newer engine release, [`android/PLAY_RELEASE.md`](../../android/PLAY_RELEASE.md)
for packaging and signing. This page explains how the thing is built and why,
and what is still missing for a Libre-life release.

## 1. What exists

| Flavor | Game | Data | Application id |
| --- | --- | --- | --- |
| `librelife` | Libre-life | player supplies a folder on the device | `by.quake.zircon.librelife` |
| `quake` | stock Quake, for testing on known content | player supplies `id1` | `by.quake.zircon.quake` |
| `objectn` | a game shipped from this shell | `assets/objectn.pk3`, generated outside this repo | `by.quake.objectn` |

One Java package, `by.quake.zircon`, for every flavor; only the application id
and the `FlavorProfile` differ. `GameActivity` extends SDL's activity, and
`LauncherActivity` runs before it.

```
android/app/src/main/
  java/by/quake/zircon/     launcher, mod scanner, folder picker, settings,
                            touch overlay, control editor, UiStyle
  java/org/libsdl/app/      SDL Java glue, imported unmodified
  cpp/touch_android.c       JNI bridge: analog input, buttons, pointer mode,
                            frame statistics, CPU affinity
  cpp/shader_cache_android.c  GLSL program binary cache
  cpp/steam_android.c       Steam stubs (Steam is Windows-only here)
  cpp/SDL2, cpp/third_party vendored upstream libraries
app/src/<flavor>/           FlavorProfile, control layout, manifest additions
tools/engine_upgrade.py     3-way merge of a new engine release
tools/check_android_patches.py  asserts every engine patch still exists
```

The engine itself is **not** in this repo. The build compiles a Zircon tree
named by `zircon.engineDir` (or `ZIRCON_ENGINE_DIR`), which carries our patches.

## 2. Engine patches

About twenty hunks across fifteen engine files. They are listed with their
purpose in `check_android_patches.py`, which fails loudly when a merge drops
one, and the upgrade procedure is in `ENGINE_UPGRADE.md`.

| Area | What the patch does |
| --- | --- |
| `vid_sdl.c` | calls the touch bridge from `Sys_SendKeyEvents` and `IN_Move`, overrides the window cursor, uses the real drawable size |
| `cl_input.c` | skips mouse-look while game code owns the pointer |
| `clvm_cmds.c` | notes when CSQC draws its own cursor (`VM_drawpic`) |
| `gl_textures.c`, `vid_shared.c` | GLES depth/stencil formats, cubemap size query |
| `gl_backend.c`, `gl_rmain.c` | shader binary cache hooks, warm-up permutation list |
| `fs.c`, `filematch_stringlist.c.h`, `sys.h` | file lookup and pack listing fixes for app storage |
| `model_alias.c`, `model_shared.h`, `prvm_cmds.c` | MD3 frame thinning and pose blending |
| `lhnet.c`, `lhnet.h` | non-Steam build fixes in the upstream release |

The upgrade from Zircon Beta 106 to 164 merged all of these automatically; only
the Steam and networking files conflicted, because upstream had absorbed that
work itself.

## 3. Content delivery

Two modes, chosen per flavor:

- **External folder.** The player copies a game folder onto the device. The
  default path is a per-flavor string resource, overridable at build time with
  `-Pzircon.gameFolder=...`, and changeable in the app: "Game folder" opens a
  browser with shortcuts, a path field, hidden folders included, and folders
  containing game data marked. The choice is stored per app and survives
  rebuilds. Needs all-files access, which the flavor's own manifest declares.
- **Bundled pk3.** One `assets/<game>.pk3` installed into app storage on first
  run. Used by the published flavor.

Play's limits are 500 MB for the base module, but **the limit that binds is the
200 MB generated download** the console computes per device. One ~147 MB pk3
clears it, which is why no asset packs or Play Asset Delivery are involved.

Game data is recognized by a pack (`.pak`, `.pk3`) **or** a loose gamedir
(`progs.dat`, `csprogs.dat`, `menu.dat`, `maps/`). Libre-life needs the second
form; testing only for packs rejects a perfectly good folder.

## 4. Controls

The overlay is an Android view above the SDL surface, not engine-drawn GL.
Movement and look are analog and never synthesized key presses: the stick feeds
`cl.mcmd.clx_forwardmove/sidemove`, drags add to `cl.viewangles`. Buttons send
either a real key event (so binds apply) or a console command.

A layout is JSON, one file per game in `assets/controls/`, copied to app storage
once the player edits it:

```json
{ "id": "fire", "icon": "fire", "type": "command", "action": "+attack",
  "mode": "hold", "show": "game", "looks": true, "x": 0.86, "y": 0.70, "size": 46 }
```

- `type`: `key` (engine key name), `command` (console; `+x` sends `-x` on release),
  `keyboard` (soft keyboard).
- `mode`: `hold`, `toggle`, `tap` (fires on release, so a long hold can open the editor).
- `show`: `game`, `console`, `both`.
- `looks`: dragging off the button also turns the view.

The editor opens from the launcher or by long-pressing a tap button in game:
drag to move, pinch to resize, add or delete custom buttons, edit action and
mode, global opacity and size, stick-zone width, reset to defaults.

Two behaviors worth knowing:

- **Pointer mode.** Game code that draws its own cursor (a lobby or page UI in
  CSQC) keeps `key_dest` at `key_game`, so the overlay cannot tell from the
  engine's state that the screen wants a pointer. The engine notes when the
  configured cursor picture is drawn (`touch_cursor_pic`, default `gfx/cursor`);
  the overlay then hides gameplay buttons, drives the cursor, and suppresses
  mouse-look so the view does not spin.
- **Gamepad.** SDL's controller path works as-is; the overlay hides on controller
  input and returns on the next touch.

## 5. Performance defaults

Shipped in `mobile_defaults.cfg`, executed after `default.cfg`:

```
r_shadow_realtime_world 0
r_shadow_realtime_world_shadows 0
r_shadow_realtime_dlight 1      // the flashlight IS a dynamic light
r_shadow_realtime_dlight_shadows 0
vid_samples 0
r_fxaa 0

// each of these renders the scene or the screen an extra time
r_water 0
r_glsl_postprocess 0
r_bloom 0
r_hdr 0
r_motionblur 0
r_damageblur 0
r_coronas 0

// 3D view to a framebuffer below screen resolution; HUD and menus stay native
r_viewfbo 1
r_viewscale_fpsscaling 1
r_viewscale_fpsscaling_target 60
r_viewscale_fpsscaling_min 0.5

cl_maxfps 0
vid_vsync 1

cl_particles_quality 0.5
cl_decals_models 0
r_lerpmodels 1                  // required if models are frame-thinned
```

Three of these are counter-intuitive:

- **`r_shadow_realtime_dlight 1`, not 0.** Turning it off is the obvious mobile
  saving and it makes the flashlight light nothing.
- **`vid_vsync 1` with `cl_maxfps 0`.** Uncapped was slower: on a MediaTek part
  every sixth swap stalled 35 ms waiting on the GPU because nothing held the
  clocks up. Blocking on the swap is the frame pacing.
- **Scale the 3D view, not the UI.** `r_viewfbo` with fps-driven scaling keeps
  text sharp while the world renders lower.

## 6. Device findings

Measured, so they are not re-derived:

- **Shader compilation is the first-run cost**, not geometry or textures. The
  port carries a program binary cache and a warm-up list; both are engine patches.
- **A periodic stall on the test device is the driver, not the engine.** On a
  PowerVR part a frame drawing nothing still cost 16 ms and a long stall arrived
  every ~170 ms. It persisted across two engine versions and was unaffected by
  shadows, sound, resolution over a 16x range, postprocess, buffer sizes, vsync,
  fps caps, picmip and compression. Test a second device before blaming content.
- **`r_speeds 2` stage timings are misattributed on a tile-based renderer.** It
  billed 42 ms to shadow maps on a frame where disabling every shadow path
  changed nothing. Compare two runs instead of reading the breakdown.
- **`timedemo` is not a benchmark here.** It replays at real time. Sample
  `host_speeds` over a fixed window anchored at the map-load line.
- **Keep build output off synced folders.** A sync client locking files
  mid-package produces Gradle errors that look like anything but the cause.

## 7. Before Libre-life can ship

Architecture is done; the remaining work is content and polish.

- **Data size.** `data/` is far larger than a Play download allows, so the
  `librelife` flavor currently expects the player to supply the folder. Shipping
  on Play needs a trimmed data set, as the sibling port did (textures downscaled,
  models frame-thinned, audio re-encoded).
- **Licensing.** Valve and id data may not ship inside a bundle; see
  [`LICENSE_AUDIT.md`](../../LICENSE_AUDIT.md), whose Part 3 covers the port's own
  dependencies and the engine's GPLv2-or-later source obligation. The store
  listing must avoid Valve trademarks and artwork.
- **QC work not yet done:** safe-area HUD anchoring from display cutouts, a touch
  scale mode for menus with 48 dp hit targets, a context "Use" hint exposed from
  `Player_Use` gating, aim assist, auto-crouch.
- **Platform polish not yet done:** Game Mode API, ADPF thermal hints, Swappy
  frame pacing, predictive back, Auto Backup rules for saves.
- **Per-game bindings.** The Libre-life layout was derived from a sibling game's,
  so some actions still use that game's keys.

## 8. Prior art

| Project | Engine | What it proves |
| --- | --- | --- |
| [QI4A](https://github.com/poVoq/Quake-1-Android-Port-QI4A) | DarkPlaces ~2012 | DP runs on Android GLES2 |
| Official DP iOS/Android port | DP + SDL 1.3 | the `VID_TouchscreenArea` overlay and `USE_GLES2` path Zircon still carries |
| [Quad Touch](https://play.google.com/store/apps/details?id=com.opentouchgaming.quadtouch) | DP, FTEQW, others | a Play-approved launcher that ships **no game data**; the player supplies files |
| [FTEDroid](https://github.com/fte-team/fteqw) | FTEQW | the fallback engine, already proven by the web port |
| [mobilerpgpack](https://github.com/sandstranger/com.mobilerpgpack.phone) | FTEQW + others | modern Gradle + CMake + launcher reference |

Measured against Quad Touch on the same phone, its Quake runs an old GLES 1
renderer at a steady 60 fps while this port runs GLES 3 with shaders; that gap
is renderer-level, not a defect in the shell.

## Sources

- [Quad Touch on Google Play](https://play.google.com/store/apps/details?id=com.opentouchgaming.quadtouch), [emileb repositories](https://github.com/emileb?tab=repositories)
- [FTEQW](https://github.com/fte-team/fteqw), [mobilerpgpack](https://github.com/sandstranger/com.mobilerpgpack.phone)
- [Zircon mirror](https://github.com/FriskTheFallenHuman/zircon-engine), [DarkPlaces](https://github.com/DarkPlacesEngine/darkplaces)
- [Play target API requirements](https://support.google.com/googleplay/android-developer/answer/11926878), [Play size limits](https://support.google.com/googleplay/android-developer/answer/9859372)
- [SDL2 Android README](https://wiki.libsdl.org/SDL2/README-android)
