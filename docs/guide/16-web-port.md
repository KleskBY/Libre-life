# 16 — Experimental browser port

Libre-life can run its existing QuakeC programs in FTEQW's WebAssembly engine.
The local prototype boots the Hazard Course, renders its BSP geometry and
textures, runs server and client game code, accepts keyboard movement, displays
the menu, and loads a second map. This is an initial compatibility port, not a
completed campaign certification or a public release.
Uplink's opening map also gets through its intro and renders the world and HUD
after increasing the VM memory limits.

## Run locally

From the repository root, with Python 3.10+, Pillow and the normal FTEQCC compiler:

```powershell
python -m pip install Pillow
python tools/web_build.py
python tools/web_serve.py
```

Open **http://127.0.0.1:8000/** and press **Launch game**. Click the game canvas
to capture the mouse and allow audio. **P** releases the mouse and opens/closes
the game menu; click the game again to resume mouse capture. **C**
crouches. The on-page **Menu**, **Settings**, and **Resume** buttons call the
actual MenuQC through FTE's `menu_cmd` command. Settings opens the Options window
directly. Escape remains available to the browser for releasing pointer lock;
normal play does not require Esc or Ctrl combinations. The web profile unbinds
Ctrl to avoid accidental browser shortcuts while crouching. The Fullscreen
button uses the browser's fullscreen API. Do not open HTML with `file://`.

All web profiles use `set sv_hitmodel 0` before MenuQC initializes. The explicit
`set` creates the cvar before QC registers it; a bare `sv_hitmodel 0` is unknown
at this stage in the pinned engine. **F** sends `cmd flashlight` directly to the
game server. The pinned browser engine's registered client `flashlight` command
did not toggle the light in testing; `cmd flashlight` works in its console too.
The builder strips aliases whose names collide with registered CSQC commands;
the old `flashlight` alias incorrectly redirected the command to impulse 14.
A downstream gamedir adds its own binds through its own
`web/<gamedir>/web.cfg`, which the builder picks up the same way.

The web shell follows the public Libre-life homepage: its logo, Oswald display
face, Share Tech Mono body face, orange/black palette, radial glow, scanlines,
square borders, and restrained hover glow are bundled locally. Game controls use
labelled SVG icon buttons in a sticky rail to the left of the game instead of
text buttons in the top navigation. The first icon links to the parent directory,
matching a `/libre-life/webport/` deployment below the mod homepage. Compact
layouts retain the rail along the left edge.

The pinned engine registers its keyboard handler on both `document` and the
canvas, and consumes printable text from both modern `keydown` and legacy
`keypress` events. This produced console input such as `ffoovv`. After engine
initialization, a launcher listener registered ahead of the engine routes focused
canvas `keydown`/`keyup` events into FTE exactly once and suppresses the redundant
legacy `keypress`. It also stops the event before FTE's document and canvas
listeners can both receive it. The modern path supplies both the physical key
and Unicode value. Browser-focused controls remain outside the engine, while
game and console keys are delivered once when the canvas is focused.

The build compiles all three QC modules, verifies the engine downloads against
`web/engine-lock.json`, and writes the distribution to gitignored `dist/web/`.
It never uploads assets. The preview server binds only to loopback and serves
only that distribution, not the repository. Stop it with Ctrl+C.

```powershell
python tools/web_build.py --profile hazard
python tools/web_build.py --profile uplink
python tools/web_build.py --profile halflife
python tools/web_build.py --profile demos
```

Each command replaces the same output with the selected profile. Hazard is the
default, containing all seven `t0a0*` maps. Uplink selects `hldemo*`; Half-Life
includes the base campaign map archive. The launcher lists only packaged maps.
The combined `demos` profile includes Quake 1 Shareware (nine playable maps),
Uplink (three), and the Hazard Course (seven), and defaults to the main menu.
It uses an explicit allowlist to exclude the full Half-Life campaign and
registered Quake episodes. Quake's twelve external brush-model BSPs are included
as assets, but are not offered as starting levels. All maps use Libre-life gameplay.
MenuQC checks for `start`, `t0a0`, `hldemo1`, and `c0a0` at initialization and
hides campaign buttons whose starting maps are absent. Installing different
assets requires reinitializing the menu/restarting the engine.

## Touch controls and phones

`web/touch.js` (shared with the quake.zone launchers) switches on for touch
screens, or with `?touch=1` / `?touch=0`. Movement is a floating left stick fed to
FTE as a virtual standard gamepad; aiming is a drag on the right half, sent as
relative mouse motion so it honours the sensitivity setting. Buttons send console
commands, so they work regardless of binds. Each page lists them in
`window.TOUCH_BUTTONS` (`web/index.html`, `web/qualker/index.html`): Fire, Aim
(`+button6`), Jump, Duck (`+button3`), Use, Reload, Sprint (`+button4`), Grenade,
Heal, Next/Previous weapon, Flashlight, plus Scores (Libre-life) or Inventory and
Drop (QUALKER). While a menu or the console is open the stick hides and taps
become absolute mouse clicks. Launch requests fullscreen of the whole game frame
(iPhone falls back to a fixed full-window frame) and Android locks landscape.
The canvas sits in a `display: contents` wrapper so Emscripten never pins its size
mid-rotation. The builder copies `touch.js` with the launcher.

The launcher fetches packages with their SHA-256 as a query string, so a CDN
cannot serve an old package against a new `build.json`, and `build.json` itself
is fetched with `no-cache`. Deployed `.gz` siblings must be rebuilt whenever a
file changes; the server prefers them over the original.

## Prepare a VPS package

```powershell
python tools/web_build.py --profile demos
python tools/web_deploy.py
```

This creates `dist/librelife-web-demos.tar.gz` and a SHA-256 sidecar. The archive
contains a `public/` web root, precompressed downloads, checksums, license and
source notices, Nginx and Apache configurations, and `DEPLOY.md`/`APACHE.md`
with installation commands. It carries no Libre-life source; `NOTICES.txt`
points to the GitHub repository instead.
Only serve `public/`. No compiler or game-server process runs on the VPS.
See [deployment instructions](../../web/deploy/DEPLOY.md) in the source tree.
The archive builder checks the game and engine hashes before packaging and
uses a fresh staging directory so stale output files cannot enter the archive.

The provided Nginx configuration uses
[gzip_static](https://nginx.org/en/docs/http/ngx_http_gzip_static_module.html)
to serve files compressed on the build computer, avoiding per-request compression
work on the VPS. It revalidates caches and returns 404 for missing assets.
DNS, TLS certificates, and uploading the package remain deployment steps.

`--skip-compile` reuses existing `.dat` files. `--compiler PATH` selects FTEQCC.
`--data PATH` selects an already prepared game directory; compilation still
outputs to the repository's `data/`, so copy the three modules into a different
asset directory before using it. `--engine-cache PATH` selects a directory
containing the pinned `ftewebgl.js`/`ftewebgl.wasm` pair. The default cache is
gitignored `.web-cache/`.

## Engine compatibility

The old upstream `moodles/web/` engine identifies itself as **FTE SVN 6202**.
It initializes WebGL but rejects this project's server program with:

```text
SV_Error: 32bit qc statement support was disabled for this platform.
```

Libre-life's globals require FTE32 bytecode. The prototype instead pins the
**July 23, 2026 development build** from
[FTE's development downloads](https://fte.triptohell.info/moodles/dev/web/).
This pair successfully executes the existing gameplay programs. MenuQC adds a
`GameCommand` entrypoint for the page buttons and supports the rebound menu key.
The engine itself is a prebuilt upstream
binary, not an engine compiled by `web_build.py`.

Downloads are mutable upstream. A changed hash fails the build instead of
mixing engine revisions. Review and test both files together before updating
the lock. The download hashes pin binaries, not a reproducible source build.

### Zoom projection

Both clients apply `STAT_ZOOM` to FTE's actual projection through
`View_ApplyZoom`. `clearscene()` leaves `VF_FOVX/Y` at zero until FTE resolves
its approximate FOV. Falling back to the `fov` cvar as a horizontal angle
disagrees with the default `scr_fov_mode 4` widescreen projection, causing a
visible jump whenever zoom starts or finishes.

The helper unprojects the screen center and two edge midpoints, takes their
distances at a common depth, and scales both frustum tangents equally. FTE
therefore remains responsible for FOV mode, aspect ratio and viewport settings.
These programs use the DarkPlaces CSQC ABI: `cs_unproject` takes virtual screen
coordinates and a view-space depth. FTE refreshes `autocvar_vid_conwidth/height`
with those virtual dimensions before each view update. The FTE `VF_AFOV` and
screen-size property numbers collide with fog properties in this ABI and
cannot replace that path. Non-FTE engines retain native `.viewzoom` handling.

Finishing the zoom-out lerp at 0.999 rather than 0.97 removes a visible step
near the end of release; the old cutoff caused one. Network zoom still
has the existing 1/255 quantization.

`tools/web_zoom_smoke.cjs` measures the WebGL perspective matrix for zoom-in,
zoom-out and unset zoom across all five FTE FOV modes and four canvas aspect
ratios. It checks that both axes scale together and return to the original
projection. Use `PLAYWRIGHT_MODULE` for the Playwright installation and
`WEB_TEST_URL` for the webport under test; the default is port 8002.
The September 18, 2026 Edge run passed 120 projection samples per build. A
normal pistol aim/release also reached zoom 0.7 and returned to 1;
the last FOV step was approximately 0.225 degrees, consistent with the network
quantization rather than the old 3% cutoff or widescreen projection switch.

## Packaging and startup

`tools/web_build.py` merges the known Half-Life map, WAD, and sound archives,
plus Uplink archives when requested. The optional local `quake_shareware.pk3`
supplies fallback models, sounds and graphics such as `progs/bolt.mdl`; its
game code is excluded. Its maps are included only in the combined demo profile.
Loose runtime files override archive entries.
Other top-level packages such as Restriction and Quake's full campaign are excluded.
The generated PK3 uses stored ZIP entries for compatibility with web builds
that omit ZIP decompression. The manifest and package are mounted through
FTE's `Module.files` API before the engine starts.

`tools/web_bsp.py` rewrites one field in Q3-format (`IBSP` v46) maps: empty
solid leaves that carry area `-1` get area `0`, which the pinned renderer
requires. Any other negative area, or one on a leaf with faces, fails the
build instead of being patched. HL and Quake BSPs pass through untouched.
`build.json` lists the patched maps under `bspEmptyLeafAreasNormalized`.

The builder includes converted IQMs and their framegroup, skin, bodyinfo and
splitbone sidecars. It excludes desktop user configs, saves, generated caches,
executables, and source files. `web/autoexec.cfg` replaces the desktop startup
config inside the package. `web/web.cfg` applies modest rendering settings,
avoids desktop-only commands, and sets `vid_conwidth`/`vid_conheight` explicitly.
The existing UI reads those cvars; a zero height placed its menu offscreen.
The web profile also allocates 64 MiB for SSQC and 32 MiB for CSQC. Uplink's
startup exhausted the engine's default 8 MiB VM allocation; increasing these
limits removed that crash.

The tested local Hazard build, including Quake fallback assets, was approximately
**195 MiB**. The observed Uplink WASM heap was approximately **531 MiB** after
increasing the VM limits, excluding the package's JavaScript storage,
decoded audio/images, GPU allocations, and browser overhead. This is a desktop
prototype; mobile memory and performance have not been validated. Content
partitioning remains a possible improvement; the deployment builder now supplies
HTTP gzip copies ahead of time.

## Verification

All three QC targets compiled with zero warnings. Browser testing used headless
Microsoft Edge with WebGL 2. A keyboard strafe changed both SSQC and CSQC player
positions, and `map t0a0b` rendered a second Hazard Course map. Tests use a fresh
browser context and do not alter the user's browser profile.

The combined demo build also passed initial main-menu startup, all campaign
availability flags (three present, full Half-Life absent), Quake `start` and
`e1m1` rendering, and the Uplink opening after 45 seconds. Its game package is
220.1 MiB; the deployment archive is about 264 MiB, with about 130 MiB of
compressed web files and 357 MiB installed. Archive checks verified every file
checksum, gzip round trips, the 19 playable maps plus twelve brush-model BSPs,
and the absence of full Half-Life/registered Quake maps. The supplied Nginx
configuration has not been run on the VPS.

A stability pass on October 13, 2026 rebuilt the demo profile (221.4 MiB) and
ran it in headless Edge with no JavaScript or fatal VM errors:

- `web_smoke.cjs` and `web_zoom_smoke.cjs` both passed.
- All 19 maps loaded twice in one session, then `changelevel` from `t0a0` to
  `t0a0a` and on to `hldemo2`.
- With `sv_cheats 1` set before the map load (it is latched), every weapon
  slot from `impulse 101` was selected, fired, aimed and reloaded on `e1m1`.
- `save`/`load` within the session restored the player to within 0.03 units
  after a 2400-unit noclip move.
- The WASM heap grew from 442 to 637 MiB over the first loads, then stayed at
  637 MiB through 48 further loads of `hldemo1`, `hldemo2`, `t0a0` and `e1m3`.
  Emscripten never returns heap pages, so this is the peak, not a leak.

In the app's visible browser pane, the Hazard Course rendered and the OpenAL
`AudioContext` reached `running` after a canvas click; audible output and
pointer lock still need a person at the keyboard.

For a repeatable smoke test, install Playwright in an ignored local directory:

```powershell
npm install --prefix .web-test playwright
$env:PLAYWRIGHT_MODULE = "$PWD/.web-test/node_modules/playwright"
node tools/web_smoke.cjs
```

Keep the preview server running while testing. Edge must be installed, or set
`WEB_BROWSER_CHANNEL=chrome` for installed Chrome. `WEB_TEST_URL` overrides the
default preview address. Logs and screenshots go into `.web-test/`.

The packaging helpers have unit tests that need no browser or assets:

```powershell
cd tools
python -m unittest test_web_bsp test_web_config
```

Remaining validation and limitations:

- Complete the Hazard Course and Uplink, including USE interactions, combat,
  scripted sequences, level transitions, and restoring persistent game state.
- Test audible playback, fullscreen/pointer lock in a visible browser, Firefox,
  Safari, and mobile devices. Audio initialization alone is not an audible test.
- The prebuilt web engine omits FreeType. The builder now uses Pillow to bake
  `gfx/font.ttf` into a proportional Kex font and texture, loaded under the same
  `gfx/font` name by MenuQC. The atlas covers ASCII, Latin-1, Latin Extended-A,
  Cyrillic, and common punctuation; other scripts still need additional glyphs
  or a custom engine with FreeType. Glyph images compensate for FTE's scaled
  bitmap drawing path, which draws a square quad even for proportional Kex
  glyphs, and store premultiplied alpha for that path's blending. Runtime TTF
  loading is still unavailable in this engine.
- Existing menu cvar registration produces nonfatal flag warnings on FTE.
- The local content set reports missing `sprites/flare1.spr`, `decals.wad`, and
  a sound precache warning for `demon/dland2.wav`, which the engine requests
  itself during player movement (no QC references it); Uplink additionally
  reports `hldemo.wad`.
  `progs/bolt.mdl` also requires the optional Quake fallback assets described
  above. The desktop intro cinematic is excluded.
- Browser saves and the project's custom save/global-state integration need
  additional work. Direct console `save quick` / `load quick` worked within a
  session and wrote `data/quick.sav` into browser localStorage. The custom
  `quicksave` command did not create a save in the tested build. Reloading the
  browser, save quotas, companions, and campaign-wide restoration have not
  been verified. Do not rely on this prototype for persistent campaign saves.
- Multiplayer has not been tested. Browser networking requires FTE's WebSocket
  or WebRTC paths, not a direct connection to an arbitrary native UDP server.

## Other porting options

| Approach | Fit for this repository |
| --- | --- |
| FTEQW WebAssembly | Smallest change: reuse QC, IQM, BSP and shader content. This prototype uses it. |
| Port Zircon with Emscripten | Better route to preserving Zircon-specific behavior, but requires engine work on graphics, the browser main loop, filesystem, audio, and networking. No maintained browser target was identified in the local Zircon engine source. |
| Reimplement on a browser-oriented engine | Largest undertaking: replace or embed the QC runtime and reproduce entities, movement, animation, asset loading and rendering. Suitable for a deliberate engine migration rather than a quick port. |

FTE's [browser integration notes](https://github.com/fte-team/fteqw/blob/master/specs/browser.txt)
and [manifest specification](https://github.com/fte-team/fteqw/blob/master/specs/fte_manifests.txt)
describe its embedding and network paths. Some examples describe older asm.js
builds, so check the current engine's `engine/web/prejs.js` and `ftejslib.js`.
[Emscripten's runtime guide](https://emscripten.org/docs/porting/emscripten-runtime-environment.html)
explains the main-loop and filesystem changes a native engine port entails.

The generated package contains user-supplied game assets; preparing an archive
does not establish redistribution rights. Engine provenance is recorded in
`web/engine-lock.json`, copied to `engine/engine-lock.json` in the build.
The included notices point to the Libre-life repository and the upstream engine
source; the exact corresponding engine source revision remains unverified. Packaging does not upload or publish the site.
