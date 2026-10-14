# 13 — Entity behaviour notes

Per-entity decisions that are not obvious from the code and do not belong to any
one system chapter: places where the port deliberately diverges from Half-Life,
where a GoldSrc feature has no engine equivalent and had to be synthesized, or
where a tuning value exists to stop something pathological.

For signatures and map keys see [reference/entities.md](../reference/entities.md)
and [reference/mapkeys.md](../reference/mapkeys.md).

## Breakables and gibs

**Gib count is capped, not computed.** Count scales with the submodel's bounding
box volume, but with a hard ceiling. On curved or hollow brushwork the submodel
bbox is the union of every brush *plus* the hollow interior, so a naive grid fill
produced hundreds of server entities, many floating in empty space. Random
placement inside an inset bbox at a bounded count matches GoldSrc's
`TE_BREAKMODEL` behaviour: the shards fill the box and the count stays sane.

**There is also a global live-gib budget.** Every breakable gib counts against it,
and a break that would exceed it spawns fewer. This exists because of chained
multi-pane breaks — `c1a1b`'s `airbust` glass chain would otherwise flood the
server with hundreds of physics entities and tank the framerate.

**Gib sets are numbered files, not bodygroups.** HL picks a random submodel
client-side; IQM has no submodel system, so each set is split into numbered files
(`woodgib01.iqm`, `woodgib02.iqm`, …) and scanned once at precache time. The scan
must happen during the precache phase: `precache_model()` after that phase drops
the engine, which is exactly what a runtime-spawned breakable from `monstermaker`
would trigger. Everything persisted to an entity or a global array is `strzone()`d,
because tempstrings from `substring`/`strcat` decay once the pool wraps (about a
second) and would silently corrupt the field.

## Pushables and buoyancy

`func_pushable` floats by replacing gravity while submerged. Net vertical
acceleration is gravity scaled by `(2 * B * frac - 1)`, so with `B = 1` the
equilibrium sits at half-submerged and the crate bobs around the waterline; drag
damps the oscillation into a gentle settle. This is the HL `FL_FLOAT` equivalent.

## Trains and blockers

A high-damage `func_tracktrain` is supposed to splatter bodies and push through.
But `MOVETYPE_PUSH` stops dead against **any** solid blocker, and a corpse left at
`SOLID_SLIDEBOX` — which is what lets the player shoot it — would halt the train
every frame. So once the blocker is dead its collision is cleared, and the pusher
integration succeeds on the next tick.

## Turrets

**`monster_miniturret`** is a floor- or ceiling-mounted automated turret that
deploys, scans, fires, and retires when idle. HL aims it with studio bone
controllers; this port rotates the whole entity instead, which needs different
angle math — see `MiniTurret_UpdateDisplayAngles` and the aiming-math rules in
[06 — Monsters](06-monsters.md). Ceiling mounts hang with `roll = 180`, and roll
inverts the local pitch axis, so the rendered pitch needs a second negation to
keep the barrel on target.

**`func_tank`** is the brush turret. It tracks the first player in PVS, rotates
toward them within `yawRange`/`pitchRange`, and fires when aim is inside the yaw
and pitch tolerances. When a player is controlling it, the gun mirrors their view
angle and fires on `+attack`.

The base file owns spawn and keyvalue parsing for the bullets variant, plus the
helpers every variant shares: `TrackTarget`, `BarrelPosition`,
`AdjustAnglesForBarrel`, `TankTrace`, `BaseFireFX`, `RotSound`,
`StartControl`/`StopControl`, `ControllerPostFrame`, `FindTarget`, `FuncTank_Init`.
The `func_tankrocket` / `func_tankmortar` / `func_tanklaser` variants live in
sibling files and set `self.tankFire` at spawn to their own per-shot body.

`func_tank` is also one of the thirteen entities that parse
`tokenize(__fullspawndata)` by hand — that is how HL's `yawrate` key maps onto the
conventional `tank_yawRate` field without breaking any map. See
[03 — Entities](03-entities.md).

## Effects with no engine equivalent

**`env_bubbles`.** HL sends `TE_FIZZ` and the engine renders sprites with vertical
drift plus an optional horizontal current. FTE and DarkPlaces have no `TE_FIZZ`,
so the effect is synthesized by spawning short-lived sprite entities on
`MOVETYPE_NOCLIP`. Keys kept from HL: `density` (bubbles per emission tick) and
`current` (horizontal speed, with the sign encoding direction — HL's
rendercolor-component packing is irrelevant once the effect is synthesized).

**Hornet tracers.** Model-flag tracers stand in for `TE_BEAMFOLLOW`: orange for
the tracking variant (HL red) and purple for the dart variant (HL orange), so the
two firemodes stay visually distinct without needing a custom sprite or particle
asset.

## Scientists

**Fear is deliberately short-ranged.** Scientists only panic at hostiles that are
*very* close — or that actually hit them, since `Scientist_Pain` flees at any
range. The original 800-unit sighting radius had every scientist on the map
bolting the moment anything hostile wandered into view.

**Scripted sentences must play during a scripted sequence.** This is the one place
that deliberately has **no `monster_cine` gate**, and it is load-bearing for set
pieces. In the `c1a0e` airlock lockdown the two scientists are walked to the
consoles and perform retina scans via `scripted_sequence` *while* delivering the
`SC_LOCK*` intercom lines. Bailing out on `monster_cine` here silenced that
intercom entirely.

The script's control still must not be stomped, so the orientation and talk-anim
overrides *are* skipped while a script owns the monster — only the audio plays.
That split is the point: audio is additive, pose is not. Compare with `th_pain`,
which must be fully gated ([05 — Damage](05-damage.md)).

## Alien controller

Flying Xen commander with two ranged attacks. Being a flier it uses
`FlyMonster_Start` rather than `WalkMonster_Start`, so it takes the
`BITS_CAP_FLY` path through the node graph (`NODE_REALM_AIR`) and ignores the
land-node drop pass entirely — see [06 — Monsters](06-monsters.md).

## Quake 1 bestiary

The `monster/q1/*` set is adapted from cleaned id1 QuakeC to fit this project's
monster base. Two things to keep in mind when touching them:

- `.float q1_monster` marks them so HL `SF_MONSTER_*` spawnflag semantics are
  **not** applied. Quake's bit 1 is *Ambush*, and the HL skill-filter bits
  256/512/1024 collide with `PREDISASTER` and `FADECORPSE`.
- They still need `FL_MONSTER` so `scripted_sequence` and `aiscripted_sequence`
  can find and possess them.

---

Previous: [12 — Assets](12-assets.md) · Back to [index](../README.md)
