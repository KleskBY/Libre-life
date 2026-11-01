# Building and running

## Clone

The tooling under `tools/` is submodules, so clone recursively:

```bash
git clone --recursive https://github.com/KleskBY/Libre-life.git
```

Already cloned flat:

```bash
git submodule update --init --recursive
```

## Compile

The compiler is FTEQCC, in `src/`. With no arguments it reads `src/progs.src`,
which fans out to the three sub-manifests and writes three `.dat` files into
`data/`:

```bash
cd src && ./fteqcc64.exe
```

| Manifest | Output | `#define` |
| --- | --- | --- |
| `src/serverqc/serverqc.src` | `data/progs.dat` | `SVQC` |
| `src/clientqc/clientqc.src` | `data/csprogs.dat` | `CSQC` |
| `src/menuqc/menuqc.src` | `data/menu.dat` | `MENUQC` |

A clean build ends with three `Done. 0 warnings` lines. Treat any warning as a
failure — see the null-function hazard in
[01 — Architecture](../guide/01-architecture.md).

## Run

Zircon is the primary target; FTEQW is used for compatibility testing.

**Zircon** is DarkPlaces-derived and does not read `.fmf` manifests. Point it at
the repo explicitly:

```bash
./librelife.exe -basedir . -game data
```

> The `-basedir` is not optional when launching programmatically — without it,
> console commands hit whatever `progs.dat` the engine found elsewhere.

**FTEQW** reads `default.fmf` (an FTE manifest: `FTEManifestVer 1`, `game data`,
`protocolname "librelife"`), so it can be launched either way:

```bash
./fteqw64.exe +game data
```

The engine caches models, skin files, and materials across `map`. After
regenerating any asset, **fully restart** — a `map` command is not enough.

## Verification

There is no unit-test suite. Verification is **build clean plus manual in-game
test**, so the build warning count is the only automatic signal — treat any new
warning as a failure.

Two hazards are worth knowing about because neither shows up as a build error:

**Silently unbound map keyvalues.** The engine matches each BSP key against the
progs field table by exact, case-sensitive name, and `ED_ParseEdict` has no
notion of a "wrong" key — an unmatched one is simply dropped. Rename a
map-bound field and it reads 0/"" forever. Being assigned somewhere in QC does
not unlock a key. See [naming.md](naming.md).

**Orphan prototypes.** `src/progs.src` sets `#pragma noref 1`. A forward
declaration with no matching definition is uninitialised: unreferenced it is
silently stripped, but referenced from a call site it ships as a symbol with no
body — clean build, null-function call at runtime. This bites per compile
target, because a prototype in shared `gamedefs.qc` whose definition lives only
under `serverqc/` is an orphan in the client and menu builds even though a
whole-tree scan sees it resolved.

### Documentation drift

```bash
python tools/qc_doc.py check
```

Exits non-zero if `docs/reference/` no longer matches the source. Fix with
`python tools/qc_doc.py build`.

## Other tools

| Command | Does |
| --- | --- |
| `python tools/gen_rtlights.py` | regenerate `data/maps/*.rtlights` |

## Steam bridge

`librelife.exe` gets Steam from `steambridge64.dll`, built from the
`tools/SteamBridge` submodule. How Libre-life uses it is in
[18 — Steam](../guide/18-steam.md); this section is only about producing and
packaging the files.

The repo root needs three files beside `librelife.exe`:

| File | In git? | Where it comes from |
| --- | --- | --- |
| `steam_appid.txt` | yes | contains `480`, Valve's Spacewar test app |
| `steambridge64.dll` | no (`/*.dll` is ignored) | built below |
| `steam_api64.dll` | no | Steamworks SDK, `redistributable_bin/win64/` |

### Rebuilding `steambridge64.dll`

Needs Visual Studio 2022 (C++ desktop workload) and the Steamworks SDK, which
is not redistributed: download it from the Steamworks partner site and unpack it
into `tools/SteamBridge/sdk/` so that `sdk/public/steam/steam_api.h` and
`sdk/redistributable_bin/win64/steam_api64.lib` exist. The DLL in use is built
against SDK 1.62.

```bash
cd tools/SteamBridge
"/c/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/MSBuild.exe" SteamBridge.sln -p:Configuration=Release -p:Platform=x64
cp x64/Release/steambridge64.dll ../../
cp sdk/redistributable_bin/win64/steam_api64.dll ../../
```

Two `MSB8012` warnings about `TargetName` are expected (the linker appends `64`
to the name on purpose). Every function the engine resolves must be exported;
`dumpbin /exports x64/Release/steambridge64.dll` should list the 20 `SB_*`
names in the bridge's `docs/API.md`.

### Packaging

`tools/QuakeGameBuilder/builder_config.json` includes `../steambridge64.dll`,
`../steam_api64.dll` and `../steam_appid.txt`, so a build copies all three into
its root. If one is missing from the repo root, the build stops with
`Include path not found` instead of quietly producing a build without Steam.

To check a build, run its `librelife.exe` with the Steam client logged in: the
console should print `Steam: successfully initialized`, and Steam should show
you as playing Spacewar.

## fteqcc gotchas

- **No string `<` / `>`.** Use `str2chr(s, i)` and compare the ints.
- **`1e9` is a parse error.** Write `1000000000`.
- **Function-typed field comparisons against `__NULL__` may not work.** Use a
  truthy test: `if (e.callback)`.
- **Parameter names must not shadow entity fields** (`spawnflags`, `target`, …).
  Rename to `sflags` / `tname`.
- **`#pragma noref 1`** applies the `noref` modifier to everything after it:
  suppresses "unused" warnings, and permits stripping a definition that is
  *neither referenced nor initialised*. It is there to silence the vendored
  `*extensions.qc` and defs files. Spawn functions have bodies, so they are
  initialised and were never at risk from it.
