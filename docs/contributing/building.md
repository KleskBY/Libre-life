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
