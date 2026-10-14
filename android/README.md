# Zircon Android port

Android shell for Zircon (a DarkPlaces fork): SDL2 app, on-screen touch controls with a layout
editor, launcher with mod browser and engine settings, and the engine patches the port needs.

One shell, several games. Each is a Gradle product flavor:

| Flavor | Game | Data |
| --- | --- | --- |
| `librelife` | Libre-life | player copies the `data` folder to `/sdcard/LibreLife` |
| `quake` | stock Quake | player copies `id1` to `/sdcard/Quake/Q1` (shared with other Android Quake ports) |
| `objectn` | ObjectN | `assets/objectn.pk3` generated outside this repo, published on Play |

Java package is `by.quake.zircon` for all flavors; the application id differs per flavor so they
install side by side (`objectn` keeps `by.quake.objectn`, its Play identity).

## Build

Needs the Android SDK, NDK 28.2.13676358, CMake 3.31.6 and JDK 21.

```bash
./gradlew.bat assembleLibrelifeDebug -Pandroid.injected.build.abi=arm64-v8a -Pzircon.engineDir=<path to engine tree>
```

Machine-specific settings do not belong in this repo. Put them in `~/.gradle/gradle.properties`:

```properties
org.gradle.java.home=D\:/Android/jdk-21.0.12.1+1
zircon.buildRoot=D\:/Android/build/zircon-android
```

and `android/local.properties` (gitignored):

```properties
sdk.dir=D:/Android/sdk
```

| Property | Meaning |
| --- | --- |
| `zircon.engineDir` | engine source tree to compile; defaults to `../engine_source` |
| `zircon.buildRoot` | where build output goes; defaults to `android/build-out`. Keep it off synced drives (OneDrive/Google Drive lock files mid-package) |
| `zircon.versionCode`, `zircon.versionName` | release versioning, see `PLAY_RELEASE.md` |
| `zircon.gameFolder` | where the built app looks for game data. Relative values resolve against shared storage, absolute ones are used as given. Defaults per flavor: `LibreLife`, `Quake/Q1`; ignored by `objectn`, whose data ships in the app |

Example, a Quake build that reads a different content folder:

```bash
./gradlew.bat assembleQuakeDebug -Pzircon.gameFolder=Games/Quake -Pzircon.engineDir=<engine tree>
```

That only sets the **default**. In the app, "Game folder" opens a browser: tap through
directories, use the Storage/Download/app-folder shortcuts, or type a path; folders that
already contain the game data are marked. The choice is stored per app, so a rebuild with a
different default does not override what the player picked.

The engine tree is **not** stored here: it is a vendored upstream dump plus our patches, managed
with `tools/engine_upgrade.py` (see `ENGINE_UPGRADE.md`). `third_party/` and `SDL2/` under
`app/src/main/cpp/` are vendored so a fresh clone builds without extra downloads.

## What is ours

- `app/src/main/java/by/quake/zircon/` — launcher, mod scanner, settings, touch overlay, control
  editor, per-flavor `FlavorProfile`.
- `app/src/main/cpp/touch_android.c` — JNI bridge: analog move/look, buttons as key events or
  console commands, pointer mode for game-drawn cursors, frame statistics, CPU affinity.
- `app/src/main/cpp/shader_cache_android.c` — GLSL program binary cache (first-run stutter).
- `app/src/main/cpp/steam_android.c` — Steam stubs; Steam is Windows-only.
- `app/src/*/assets/controls/*.json` — default control layouts per game.
- `tools/` — engine upgrade and patch verification.

Everything under `app/src/main/cpp/SDL2`, `app/src/main/cpp/third_party` and
`app/src/main/java/org/libsdl/app` is upstream code, left as imported.

## Documentation

- `ENGINE_UPGRADE.md` — moving to a newer Zircon release and keeping the patches.
- `PLAY_RELEASE.md` — building and signing a Play bundle.
- `../docs/guide/17-android-port.md` — the published write-up of how the port works.
