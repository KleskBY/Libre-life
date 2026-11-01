# Libre-life

Libre-life is an open-source QuakeC project that recreates Half-Life-style gameplay on Quake-derived engines. It combines Half-Life compatibility with Quake 1 and Quake 3 map conventions, an extended VGUI-style interface, and the rendering and tooling capabilities of modern FTE and DarkPlaces-family engines.

The project is intended to grow beyond a total-conversion mod into a reusable framework for original games and mods.

## Current status

- Half-Life BSP maps load and core gameplay is partly playable.
- The Hazard Course and Uplink can be played from start to finish.
- Quake 1 ID1 BSP support is available, with the original episode playable using the Half-Life inventory.
- All Half-Life weapons are implemented through a shared weapon metadata system.
- Many Half-Life monsters and the full Quake 1 bestiary have working behavior.
- Doors, platforms, trains, triggers, buttons, breakables, chargers, scripted sequences, and other common entities are implemented.
- An `info_node` navigation graph supports monster pathfinding.
- Server, client, menu, HUD, save, transition, and UI systems are under active development.
- Zircon (DarkPlaces) is the primary engine target, with FTEQW used for compatibility testing.

These features are still being refined, and some behavior differs from the original games.

## Known limitations

- Sound effects do not yet have complete reverberation and spatial effects.
- The animation system still has known problems.
- Client-side prediction for multiplayer is incomplete.

## Project direction

The immediate goal is a useful Half-Life modification that supports original Half-Life maps, Quake 1 content, the project's extended UI, and a practical development workflow.

The long-term goal is a standalone game and free modding ecosystem with:

- A two to three hour original campaign.
- Solo play and two to four player cooperative play.
- Three original Deathmatch arenas.
- Keyboard, mouse, controller, joystick, and Android controls.
- Windows x64, Linux x86_64, and Android arm64 releases.
- Original or verified freely redistributable game assets.
- Visual tools for the core model, animation, material, texture, sound, sprite, and map-entity pipeline.
- Complete engine, mod, mapping, build, asset, and server documentation.
- Source assets, build scripts, examples, templates, and attribution records for new projects.

Version 1.0 is projected for December 2027. This is a planning target and can move if development or review work requires more time.

## Documentation

Full documentation lives in [`docs/`](docs/README.md):

- **[Guide](docs/README.md#guide--how-the-game-works)** — how the game works, from
  engine launch through server creation, entity spawning, and level transitions,
  with diagrams.
- **[Code reference](docs/reference/index.md)** — generated from the QuakeC
  sources, including the [entity catalog](docs/reference/entities.md) and the
  [map keyvalue reference](docs/reference/mapkeys.md) for mappers.
- **[FTEQCC Documentation](https://icculus.org/~marco/quakec/fteqcc_manual.txt)** — document specifies FTEQCC programming standard
   and use of the compiler.
- **[QuakeC Manual](https://quake.by/docs/quakec.pdf)** — introduction to QuakeC coding.
- **[Contributing](docs/contributing/building.md)** — building, naming
  conventions, and the documentation-comment convention.

  

## Building and running

Clone with submodules so the tooling under `tools/` is populated:

```
git clone --recursive https://github.com/KleskBY/Libre-life.git
```

If you already cloned without `--recursive`, run `git submodule update --init --recursive`.

Gameplay code is written in QuakeC and compiled with FTEQCC into three modules:

- `data/progs.dat` — server gameplay, entities, and AI.
- `data/csprogs.dat` — client, HUD, and view logic.
- `data/menu.dat` — menu logic.

The compiler and engine are deliberately not included. Download FTEQCC from the [official site](https://www.fteqcc.org/) or build it from the [FTEQW repository](https://github.com/fte-team/fteqw), then run it from `src` so it reads `progs.src`, which fans out to the three target manifests (`serverqc.src`, `clientqc.src`, `menuqc.src`). A clean build finishes with `Done. 0 warnings` per module.

Running Libre-life requires a compatible engine and user-supplied Half-Life assets. Place legally obtained Half-Life models, textures, sounds, and maps under the `data` game directory without redistributing them, then launch with `+game data`:

```
./fteqw64.exe +game data
```

Some Valve files the game reads are not included either. Copy them from your own Half-Life installation:

| From | To | Used for |
| --- | --- | --- |
| `valve/titles.txt` | `data/titles.txt` | on-screen message definitions for `env_message` |
| `valve/sound/sentences.txt` | `data/sound/sentences.txt` | the speech system's sentence groups |
| `valve/sprites/*.spr` | `data/sprites/` | beams, blood, muzzle flashes, and other effect sprites |
| `valve/gfx/*` | `data/gfx/` | menu background, console background, cursor, loading and pause images |

The UI font is included: `data/gfx/font.ttf` is DejaVu Sans, redistributed under the Bitstream Vera license (see [`licenses/DejaVu-Fonts-License.txt`](licenses/DejaVu-Fonts-License.txt)).

Engine builds ship `bin64/zlib1.dll` (zlib 1.2.11) under the zlib license (see [`licenses/zlib-License.txt`](licenses/zlib-License.txt)).

Windows builds ship `steambridge64.dll` from [SteamBridge](https://github.com/KleskBY/Steam-SDK-Bridge-for-DarkPlaces) under the GPL v3 (see [`licenses/SteamBridge-License.txt`](licenses/SteamBridge-License.txt)) and Valve's `steam_api64.dll` from the Steamworks SDK under Valve's terms (see [`licenses/Steamworks-Redistributable.txt`](licenses/Steamworks-Redistributable.txt)), plus a `steam_appid.txt` set to the test app ID 480. See the [Steam guide](docs/guide/18-steam.md).

## Tooling

An experimental FTEQW WebAssembly launcher is available. Run
`python tools/web_build.py` and then `python tools/web_serve.py` to try the
Hazard Course at `http://127.0.0.1:8000/` using your local assets. See the
[web port guide](docs/guide/16-web-port.md) for profiles, testing and limitations.

Development helpers live under `tools/` as pinned submodules:

- `tools/QuakeGameBuilder` — a Python/PyQt6 tool that scans the QuakeC source and assets and copies only what a build actually uses into a clean package. Install its one dependency with `pip install PyQt6`, then run `tools/QuakeGameBuilder/run.bat` (GUI) or `python tools/QuakeGameBuilder/quakebuild.py` (CLI). See its own README for configuration details.
- `tools/mdl2iqm` — converts Half-Life `.mdl` models to the engine's IQM format.
- `tools/SteamBridge` — the source of `steambridge64.dll`, the Windows DLL that gives the engine Steam (relay multiplayer, invites, achievements) without linking the Steamworks SDK into the engine. Build steps are in [building.md](docs/contributing/building.md#steam-bridge); its own `docs/` cover the API, engine hooks and QuakeC usage.

`tools/gen_rtlights.py` generates DarkPlaces `.rtlights` from Half-Life BSP maps (`python tools/gen_rtlights.py --maps-dir <your Half-Life/valve/maps>`).

## Assets and content

The repository does not distribute Valve game data. Developers provide required Half-Life models, textures, sounds, maps, and related files from their own legally obtained installation. Converted copies must remain local and must not be included in a public package.

The standalone version 1.0 goal requires original or verified freely redistributable replacements for every distributed asset. Each replacement will have documented authorship, source, license, and attribution requirements.

## Licensing status

GPLv3 is the intended license for the Libre-life codebase, and the majority of the project was written specifically for Libre-life. 
The project intends to resolve uncertain files through documentation, review, replacement, or reimplementation and to confirm the final licensing position with a legal specialist. 

## Contributing

Testing, documentation, original maps, original assets, and well-documented code contributions are welcome. Contributions should identify their author, source, and license. Do not submit Valve game assets, copied Half-Life SDK code, or material with unclear redistribution rights.

## Notice

Libre-life is not affiliated with Valve Corporation. Half-Life and related assets and trademarks belong to their respective owners.
