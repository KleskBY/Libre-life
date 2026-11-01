# Libre-life documentation

Libre-life is a total conversion that ports Half-Life entities, weapons, and
gameplay onto a DarkPlaces-derived engine. The gameplay code is QuakeC compiled
by FTEQCC into three separate programs; the assets are supplied by the user from
a legally obtained copy of Half-Life.

These docs are in three parts.

## Guide — how the game works

Read in order the first time; each page assumes the ones before it.

| | Page | Covers |
| --- | --- | --- |
| 01 | [Architecture](guide/01-architecture.md) | three VMs, the build, the FTE/DarkPlaces split |
| 02 | [Lifecycle](guide/02-lifecycle.md) | launch → menu → server → spawn → frame loop |
| 03 | [Entities](guide/03-entities.md) | the spawn contract, map keyvalues, `__fullspawndata` |
| 04 | [Use dispatch](guide/04-use-dispatch.md) | `.use` vs `.usehl`, `FCAP_*`, target chains |
| 05 | [Damage](guide/05-damage.md) | `T_Damage`, `takeDmgFn`, pain, death, gibs |
| 06 | [Monsters](guide/06-monsters.md) | monster states, AI, the `info_node` graph |
| 07 | [Weapons](guide/07-weapons.md) | the registry, `WID_*` vs `WEAPON_*`, attack cycle |
| 08 | [Player](guide/08-player.md) | spawn, hulls, stance, the split body model |
| 09 | [Persistence](guide/09-persistence.md) | level change, saves, hub snapshots, global state |
| 10 | [Client and HUD](guide/10-client-hud.md) | CSQC init, stats, networked entities |
| 11 | [Menu](guide/11-menu.md) | MENUQC, cvar staging, Create Server |
| 12 | [Assets](guide/12-assets.md) | `mdl2iqm`, bodygroups, shaders, lighting |
| 13 | [Entity behaviour notes](guide/13-entity-notes.md) | per-entity divergences from Half-Life and why |
| 14 | [Particles](guide/14-particles.md) | `effectinfo.txt` on DarkPlaces, `r_part` on FTEQW, one mod for both |
| 15 | [Bots](guide/15-bots.md) | multiplayer bots: the brain entity, their own waypoint graph, scored decisions, cvars and commands |
| 16 | [Experimental web port](guide/16-web-port.md) | local FTE WebAssembly build, packaging, browser testing and limitations |
| 17 | [Android port](guide/17-android-port.md) | the Zircon Android shell in `android/`: flavors, engine patches, touch controls, content delivery, what Libre-life still needs |
| 18 | [Steam](guide/18-steam.md) | the SteamBridge DLL, app ID 480 test builds, relay multiplayer, the Steam builtins from QuakeC |

## Reference — generated from the source

[`reference/`](reference/index.md) is produced by `python tools/qc_doc.py build`
and **must not be hand-edited**. To change it, edit the doc comments in `src/`
and regenerate.

The cross-cutting catalogs are the useful entry points:

- [Entity catalog](reference/entities.md) — every classname a `.bsp` can spawn
- [Map keyvalues](reference/mapkeys.md) — fields bound by exact name
- [Weapon registry](reference/weapons.md) — `WID_*` ↔ `WEAPON_*`
- [Cvars](reference/cvars.md) and [Builtins](reference/builtins.md)

## Contributing

- [Building](contributing/building.md) — compiler, targets, running the engine
- [Naming](contributing/naming.md) — the four contracts enforced outside the compiler
