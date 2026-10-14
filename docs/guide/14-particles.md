# Particles: DarkPlaces and FTEQW

Libre-life ships against two renderers with two entirely separate particle
systems. Neither is enabled by default in a way that looks good, and both fail
silently: you get flat coloured squares and no warning anywhere. This page
covers what each engine actually does, how to author effects for it, and how to
write one mod that looks right on both.

## The symptom

Stock Quake particles are single unlit pixels drawn as camera-facing quads with
no texture. Blood is a cloud of red dots; a shotgun impact is a puff of grey
dots. If that is what you are seeing, the engine is running its *classic*
particle path and nothing you write in QuakeC will change it. The fix is a
client configuration change, not a code change.

| Engine | Cvar to check | Bad value | Good value |
| --- | --- | --- | --- |
| DarkPlaces / Zircon | `cl_particles_quake` | `1` | `0` |
| FTEQW | `r_particlesystem` | `classic` | `script` |
| FTEQW | `r_particledesc` | `classic` | `spikeset effectinfo` |

## Two systems at a glance

|  | DarkPlaces / Zircon | FTEQW |
| --- | --- | --- |
| Script file | `effectinfo.txt` (gamedir root) | `particles/<name>.cfg` |
| Selector cvar | none, always loaded | `r_particledesc` |
| Block keyword | `effect <name>` | `r_part <name>` |
| Chaining | repeat `effect <name>` | `r_part +<name>` |
| Texture | index into an 8x8 atlas | any image or inline shader |
| Reload | `cl_particles_reloadeffects` | re-set `r_particledesc` |
| Per-map override | `<mapname>_effectinfo.txt` | none |

They share exactly one thing: the QuakeC API. Both expose
`particleeffectnum(name)` and `pointparticles` / `trailparticles`, and both
resolve `name` against whatever script the engine has loaded. That is the seam
you write your mod against.

## DarkPlaces and Zircon: `effectinfo.txt`

### Loading

The engine loads `effectinfo.txt` from the gamedir on client start and on every
map load. Zircon then looks for `<mapname>_effectinfo.txt` alongside it and
parses that second, so a map can override or extend the global set. A custom
file passed explicitly suppresses the per-map pass.

Nothing warns you if the file is missing. All 36 built-in effect names still
exist with hardcoded behaviour, so a typo'd or absent file simply means you get
stock Quake visuals for the effects you thought you had replaced.

Reload without restarting:

```
cl_particles_reloadeffects
```

### The 36 reserved names

These names are pre-registered by the engine and fired directly by network
temp-entity messages and entity effect flags. Redefining one in
`effectinfo.txt` replaces the hardcoded visual everywhere it is used, including
from stock `te_*` builtins in QuakeC.

```
TE_GUNSHOT          TE_GUNSHOTQUAD      TE_SPIKE            TE_SPIKEQUAD
TE_SUPERSPIKE       TE_SUPERSPIKEQUAD   TE_WIZSPIKE         TE_KNIGHTSPIKE
TE_EXPLOSION        TE_EXPLOSIONQUAD    TE_TAREXPLOSION     TE_TELEPORT
TE_LAVASPLASH       TE_SMALLFLASH       TE_FLAMEJET         EF_FLAME
TE_BLOOD            TE_SPARK            TE_PLASMABURN       TE_TEI_G3
TE_TEI_SMOKE        TE_TEI_BIGEXPLOSION TE_TEI_PLASMAHIT    EF_STARDUST
TR_ROCKET           TR_GRENADE          TR_BLOOD            TR_WIZSPIKE
TR_SLIGHTBLOOD      TR_KNIGHTSPIKE      TR_VORESPIKE        TR_NEHAHRASMOKE
TR_NEXUIZPLASMA     TR_GLOWTRAIL        SVC_PARTICLE
```

`TE_*` are one-shot point effects. `TR_*` are trails, spawned along a line
segment and driven by `.traileffectnum` or the legacy `.effects` bits. Any name
you invent that is not on this list becomes a new effect, reachable only
through `particleeffectnum("yourname")`.

### Block format

A block starts at `effect <name>` and runs until the next `effect` line. Listing
the same name several times *stacks* the blocks: all of them fire together. This
is how a single impact gets a decal, a spark burst, and a smoke puff.

```
effect TE_GUNSHOT
countabsolute 1
type decal
tex 56 59
size 1.5 1.5
alpha 128 128 0
originjitter 6 6 6

effect TE_GUNSHOT
count 6
type spark
color 0xc06010 0xc06010
size 0.3 0.4
alpha 0 64 64
gravity 0.4
bounce 1.5
velocityoffset 0 0 20
velocityjitter 100 100 100
```

Most numeric keywords take a `min max` pair and the engine picks a uniform
random value in between. `color` takes two hex values and interpolates.

### Keyword reference

**Spawn count and gating**

| Keyword | Meaning |
| --- | --- |
| `count <n>` | particles per unit of effect intensity (scales with the `count` argument) |
| `countabsolute <n>` | exactly `n`, ignoring intensity. Use for decals and single flashes |
| `trailspacing <qu>` | for trails, one particle every `n` units of path |
| `underwater` / `notunderwater` | fire only in, or only outside, a liquid |

**Type and appearance**

| Keyword | Meaning |
| --- | --- |
| `type <t>` | `alphastatic` `static` `smoke` `spark` `bubble` `blood` `beam` `snow` `rain` `decal` `entityparticle` |
| `tex <min> <max>` | index range into `particles/particlefont.tga`, an 8x8 grid, indices 0 to 63 |
| `tex2` | second texture for animated particles |
| `color <a> <b>` | hex range, e.g. `0xc06010 0xffd080` |
| `size <min> <max>` | diameter in quake units |
| `sizeincrease <n>` | growth per second |
| `alpha <min> <max> <fade>` | 0 to 256; `fade` is units lost per second |
| `blend <mode>` | `alpha` `add` `invmod` |
| `orientation <o>` | `billboard` `oriented` `spark` `beam` |
| `rotate <min> <max> <spinmin> <spinmax>` | initial angle and spin rate |
| `stretchfactor <n>` | length multiplier for spark and beam types |

**Motion**

| Keyword | Meaning |
| --- | --- |
| `gravity <n>` | 1 is normal, negative floats upward |
| `bounce <n>` | 0 passes through, 1 is a perfect bounce, negative dies on contact |
| `airfriction` / `liquidfriction` | drag |
| `originjitter <x> <y> <z>` | random spawn offset |
| `velocityjitter <x> <y> <z>` | random velocity |
| `originoffset` / `velocityoffset` | fixed offset added to every particle |
| `relativeoriginoffset` / `relativevelocityoffset` | same, in the effect's forward/right/up frame |
| `velocitymultiplier <n>` | scale of the velocity argument passed in |
| `time <min> <max>` | lifetime in seconds |

**Stains, decals, light**

| Keyword | Meaning |
| --- | --- |
| `staintex` / `staincolor` / `stainsize` / `stainalpha` | mark left where the particle lands |
| `stainless` | suppress the stain entirely |
| `lightradius` / `lightcolor` / `lightradiusfade` / `lighttime` | attached dynamic light |
| `lightshadow` | whether that light casts shadows |
| `lightcorona <inten> <size>` | corona flare on the light |

### The texture atlas

`tex` indexes `particles/particlefont.tga` as an 8x8 grid of 64 cells. The stock
layout puts smoke and blobs in the low indices, sparks in the middle, decals in
the 50s and 60s. Cells 56 to 59 are the bullet-hole decal family; 62 is the
bubble. Replace the file to reskin every effect at once, but keep the grid: the
indices are hardcoded across every `effectinfo.txt` in existence.

Zircon can rebuild the atlas from loose images with `particles_join`, reading
`particles/images/`.

### Useful cvars

| Cvar | Effect |
| --- | --- |
| `cl_particles_quake 0` | **required.** `1` forces stock Quake visuals and ignores `effectinfo.txt` |
| `cl_particles_quality 1` | multiplier on every `count`; raise for denser effects |
| `cl_particles_size 1` | multiplier on every `size` |
| `cl_particles_blood 1` | blood on or off, plus `cl_particles_blood_alpha` |
| `cl_particles_blood_bloodhack 1` | converts stock `svc_particle` red bursts into real blood effects |
| `cl_particles_bulletimpacts`, `_sparks`, `_smoke`, `_bubbles`, `_rain`, `_snow` | per-category toggles |
| `cl_particles_collisions 1` | let particles trace against the world (needed for `bounce`) |
| `cl_decals 1`, `cl_decals_max`, `cl_decals_time`, `cl_decals_fadetime` | decal budget and lifetime |
| `cl_decals_newsystem_bloodsmears 1` | directional blood smears rather than round splats |
| `cl_stainmaps` | legacy lightmap darkening, independent of decals |

## FTEQW: the script particle system

### Selecting a set

FTE keeps particle descriptions in named sets. `r_particledesc` takes a
**space-separated list**, loaded left to right, with later definitions
overriding earlier ones for the same effect name.

```
r_particlesystem "script"
r_particledesc "spikeset effectinfo"
```

Four sets are compiled into the executable and need no files on disk:

| Set | Character |
| --- | --- |
| `spikeset` | the good default. Textured blood, sparks, smoke trails, explosions |
| `faithful` | classic Quake looks and palette, but with real particle physics |
| `highfps` | stripped down for weak hardware |
| `tsshaft` | lightning and beam focused |
| `classic` | stock pixels. This is what you are trying to get away from |
| `none` | disables particles |

`spikeset` defines, among others: `te_blood`, `te_gunshot`, `te_explosion`,
`te_spike`, `te_lavasplash`, `te_teleportsplash`, `te_tarexplosion`,
`te_lightningblood`, `rockettrail`, `t_grenade`, `t_gib`, `t_zomgib`,
`te_railtrail`, `cu_flame`, `cu_torch`.

Anything else in the list is read from `particles/<name>.cfg` in the gamedir.

### `effectinfo` compatibility

`effectinfo` is a special entry that makes FTE parse a DarkPlaces
`effectinfo.txt` and translate it into native particle types. It is the fastest
way to make an existing DarkPlaces mod look correct under FTE.

It is a translation, not an emulation. Expect it to be *close*, not identical:
the importer covers the common keywords and drops what has no native
equivalent, and the underlying physics differ. Effects tuned in DarkPlaces may
read slightly brighter, denser, or shorter-lived. Spike's own position is that
native `r_part` is the better target and effectinfo mode is a migration aid.

Practical consequence: put `effectinfo` **last** in the list so your custom
names win, and keep a native set before it so the stock `te_*` effects your
`effectinfo.txt` does not define still get a good implementation.

Imported effects are placed in a namespace derived from the config name. If a
lookup for a bare name fails, qualify it (`effectinfo.dust`).

### Block format

`r_part <name>` opens a block. `r_part +<name>` appends another particle
description to the same effect; a block **without** the `+` resets the chain,
which makes accidental redefinition silent and destructive.

```
r_part blood_impact
{
	texture "particles/blood.tga"
	die 2 1.2
	scalefactor 1
	scale 6 10
	alpha 0.9
	alphadelta -0.5
	rgb 128 0 0
	spawnmode ball
	spawnorg 4
	randomvel 60 40
	gravity 320
	friction 0.4
	blend blendalpha
	cliptype blood_splat
	assoc blood_mist
}
```

### Keyword reference

**Appearance**

| Keyword | Meaning |
| --- | --- |
| `texture <path>` | image file |
| `shader <name> [{ body }]` | inline Q3 shader. Overrides blend modes entirely |
| `tcoords <s1> <t1> <s2> <t2> <imagewidth>` | sub-rectangle of the texture |
| `scale <min> [max]` | starting diameter in quake units |
| `scalefactor <frac>` | `1` scales with distance normally, `0` is constant screen size |
| `scaledelta <n>` | growth per second |
| `alpha <n>` / `alphadelta <n>` | 0 to 1, and change per second |
| `rgb <r> <g> <b>` / `rgbdelta <r> <g> <b>` | 0 to 255, and change per second |
| `blend <mode>` | `blendalpha` `adda` `add` `modulate` `invmod` |
| `rotationstart` / `rotationspeed` | spin |

**Lifetime and motion**

| Keyword | Meaning |
| --- | --- |
| `die <max> [min]` | lifetime in seconds |
| `randomvel <horiz> [vert]` | spawn velocity spread |
| `veladd <n>` / `orgadd <n>` | offset along the effect's direction vector |
| `gravity <n>` | acceleration in quake units per second squared |
| `friction <n>` | drag |
| `spawnmode <m>` | `box` `ball` `circle` `uniformcircle` `telebox` `lavasplash` `syncfield` `distball`; for trails `spiral` `tracer` |
| `spawnorg <n>` / `spawnvel <n>` | radius and speed used by the spawn mode |
| `areaspread` / `areaspreadvert` | dimensions for `circle` |
| `count <n>` | particles per invocation |

**Type**

| `type` | Behaviour |
| --- | --- |
| `normal` | rotating 2D billboards. Default |
| `spark` | untextured lines, length proportional to speed |
| `texturedspark` | same, but textured and aligned to motion |
| `beam` | trails only. One continuous textured beam along the path |
| `decal` / `cdecal` | clipped to BSP geometry only |
| `udecal` | unclipped decal |

**Linking**

| Keyword | Meaning |
| --- | --- |
| `assoc <effect>` | spawn this other effect at the same moment |
| `emit <effect>` / `emitinterval <s>` | each live particle periodically emits another effect |
| `cliptype <effect>` | effect spawned where a particle hits the world |
| `clipcount <n>` / `clipbounce <n>` | how many, and bounce behaviour on impact |

`r_effect "<modelpath>" <effect>` binds an effect to a model, so any entity
using that model emits it. `r_trail "<modelpath>" <effect>` does the same for
trails. This is how `spikeset` attaches flames to `progs/flame.mdl` with no
QuakeC at all.

### Useful cvars

| Cvar | Effect |
| --- | --- |
| `r_particlesystem script` | **required.** `classic` bypasses all scripts |
| `r_particledesc "<list>"` | the set list. Re-setting it reloads immediately |
| `r_part_density <n>` | multiplier on every `count` |
| `r_part_maxparticles` / `r_part_maxdecals` | budgets. Raise for dense effects |
| `r_part_sparks_textured 1` | textured spark quads instead of hairline pixels |
| `r_part_sparks_trifan 1` | triangle-fan spark geometry |
| `r_part_contentswitch 1` | swap effects underwater |
| `r_part_beams 1` | beam-type particles |
| `r_part_rain` / `r_part_rain_quantity` | surface-emitted weather |
| `r_bouncysparks 1` | particles trace against surfaces, producing stains and decals |
| `r_particle_tracelimit <n>` | per-frame trace budget for particle physics |
| `r_part_classic_square 0` | square or round classic particles. Only affects the classic path |

## Writing one mod for both

The QuakeC API is identical on both engines, so effects stay in the gamecode and
the look stays in data.

```c
pointparticles(particleeffectnum("dust"), org, dir, count);
trailparticles(ent, particleeffectnum("TR_ROCKET"), start, end);
```

`particleeffectnum` returns an index the engine resolves against its loaded
scripts. On DarkPlaces this searches `effectinfo.txt`; on FTE it searches the
loaded `r_particledesc` sets. A miss returns an index that produces nothing,
with no console warning. This is the failure mode you will spend the most time
on: nothing looks broken, an effect is simply absent.

The pragmatic split:

1. **Author in `effectinfo.txt`.** It is the lower common denominator and both
   engines read it. DarkPlaces uses it natively; FTE imports it.
2. **Cover the reserved names first.** `TE_GUNSHOT`, `TE_BLOOD`, `TE_EXPLOSION`,
   `TR_ROCKET`, `TR_BLOOD`. These fire from stock temp entities, so they light
   up without any new gamecode.
3. **Let a native FTE set backstop the gaps.** `r_particledesc "spikeset
   effectinfo"` means every reserved name you have not written yet still gets a
   decent visual under FTE instead of falling back to pixels.
4. **Ship both configs.** DarkPlaces needs `cl_particles_quake 0`; FTE needs
   `r_particlesystem script` and a non-classic `r_particledesc`. Neither default
   is what you want.

Verify by firing one effect of each class and watching for absence, not for
ugliness. A wall impact exercises decals and sparks; shooting an NPC exercises
blood and stains; a rocket exercises trails and explosions.

## Gotchas

| Symptom | Cause |
| --- | --- |
| Flat coloured squares everywhere | `cl_particles_quake 1` on DarkPlaces, or `r_particlesystem classic` / `r_particledesc classic` on FTE |
| One specific effect missing, rest fine | `particleeffectnum` name typo, or the name is not defined in any loaded set. No warning is printed |
| Effects vanished after adding a `.cfg` | an FTE `r_part <name>` without `+` reset a chain another set had built |
| Edits to `effectinfo.txt` do nothing | not reloaded. `cl_particles_reloadeffects` on DarkPlaces; re-set `r_particledesc` on FTE |
| Looks right in DarkPlaces, washed out in FTE | effectinfo import approximation. Rewrite the block as a native `r_part` |
| `bounce` and `cliptype` do nothing | `cl_particles_collisions 0` on DarkPlaces, or `r_bouncysparks 0` / exhausted `r_particle_tracelimit` on FTE |
| Decals never appear | `cl_decals 0`, or `cl_decals_max` exhausted by an earlier burst |
| Dense at close range, sparse far away | `count` scales with the intensity argument. Use `countabsolute` for fixed counts |
| Custom `particlefont.tga` breaks every effect | `tex` indices are positional in the 8x8 grid. Keep the layout |
