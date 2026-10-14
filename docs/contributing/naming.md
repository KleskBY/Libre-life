# Naming conventions

## Style

Functions are **`Subject_ActionCamel`**. `Subject` is the natural spelling with
acronyms preserved (`MP5_`, `UI_`, `AI_`, `_UseHL`); `Action` is UpperCamelCase
with no internal underscores.

| Category | Convention |
| --- | --- |
| Functions | `Subject_ActionCamel` |
| Entity spawn functions | **exact BSP classname, lowercase — FROZEN** |
| Map-bound fields | **exact BSP key name — FROZEN** |
| Engine entry points / builtins | **FROZEN** (`main`, `StartFrame`, `CSQC_*`, `m_*`) |
| Internal fields | `subject_camelCase` (`hgrunt_lkp`, `tank_yawRate`, `player_longJump`) |
| Globals | `g_camelCase` when mutable and cross-file; `SCREAMING_SNAKE` for constants |
| `#define` constants | `SCREAMING_SNAKE` |
| Function-like macros | same as functions (`Monster_HasMemory`) |
| Locals / parameters | `camelCase` |
| Cvars, console commands, sentence groups, animation names | **FROZEN** — data contracts |

## The four names you must never change

These are enforced **outside the compiler**. Violating any of them produces a
clean build and a silent runtime failure, so they are worth knowing before you
rename anything.

**1. Spawn functions.** The engine reads `"classname" "x"` from the BSP entity
lump and calls the global QC function named exactly `x`. There is no spawnfunc
table in this project. Rename one and the entity stops spawning; the engine logs
it, but only under `developer 1`.
→ [Entity catalog](../reference/entities.md)

**2. Map-bound fields.** `ED_ParseEdict` matches each BSP key against the progs
field table by exact, case-sensitive name. Rename the field and there is no
longer anything for the key to bind to — the value is dropped and nothing in QC
can name it. **Being assigned in QC does not unlock a key**; a field is map-bound
because some `.bsp` writes it. That is why `env_beam` carries PascalCase fields
like `BoltWidth` — Valve FGD spellings, not normalisable.
→ [Map keyvalues](../reference/mapkeys.md)

**3. Engine entry points and builtin bindings.** `main`, `StartFrame`,
`PlayerPreThink`, the `CSQC_*` set, the menuqc `m_*` set, and `= #0:name`
builtin bindings such as `modelframecount`, which resolve by the name string.

**4. Engine-written globals.** `__fullspawndata` (FTE fills it before every spawn
function) and `skill`.

Treat all four as frozen. If you believe one genuinely has to move, raise it
first — every one of them fails silently, so a mistake here surfaces as a broken
entity hours into a playthrough rather than as a build error.

## Grandfathered — deliberate, do not "fix"

`SUB_`, `T_Damage` / `T_RadiusDamage` / `T_Heal`, `UI_` / `HUD_` / `PM_` / `SV_`
/ `CSQC_`, the ALLCAPS weapon prefixes (`MP5_`, `SHOTGUN_`, …),
`pActivator` / `pCaller`, and the monster abbreviations `Garg_` / `HGrunt_` /
`HAssn_`.

Stock-Quake globals keep their id1 spelling: `activator`, `gameover`,
`movedist`, `enemy_range`, `intermission_running`.

## The escape hatch

Thirteen entities parse `tokenize(__fullspawndata)` by hand. There the **key
strings** are frozen but the field names are free — that is how `func_tank` maps
HL's `yawrate` onto `tank_yawRate`. If a field must be renamed and it is
map-bound, this is the route.

## If you do rename something

Prove the change did exactly what you intended and nothing else. A rename that
compiles is not a rename that worked — every contract in this file fails
silently.

Watch for **prototypes** especially. A forward declaration whose definition you
renamed is left uninitialised; unreferenced it is silently stripped, and
referenced it can ship as a symbol with no body — clean build, null-function
call at runtime. Three forms exist and it is easy to see only the first:

```c
void Foo(entity e);              // modern
void(entity e) Foo;              // old-style  <- easy to miss
void(entity e) Foo               // old-style definition, body brace next line
{
```

This is per compile target: a prototype in shared `gamedefs.qc` whose definition
lives only under `serverqc/` is an orphan in the client and menu builds even
though a whole-tree scan sees it resolved.

Then load a map and exercise the entity you touched — a spawn function or map
key that stopped binding produces no diagnostic at all.
