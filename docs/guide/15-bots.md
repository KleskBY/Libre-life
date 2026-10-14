# Bots

Multiplayer bots: `cmd bot add` fills a server, and `bot_count` keeps it filled.
They navigate a graph of their own, fight with the weapons they find, and are
driven entirely from QC, because the engine gives a bot client no usercmd.

The code lives in `serverqc/bot/`, ported from QUALKER. Two hooks connect it to
the rest of the game: `Bot_Balance` from `StartFrame`, and `Bot_PerFrame` from
`PlayerPreThink`, before physics consumes the movement it writes.

## The brain is a separate entity

`PlayerPostThink` returns early for a dead player, and the player edict's own
`.think` belongs to `Player_Dead`, which `PlayerPreThink` restores. So each bot
gets a companion `bot_brain` edict thinking at `BOT_TICK`, which does sensing,
decisions and path requests. Aim, steering and the trigger run at frame rate
from `Bot_PerFrame`, because they need frame resolution.

## Their own waypoint graph

Almost no deathmatch map has `info_node`s, so the bots build a graph instead:
flood fill from spawn points and items, a surface sweep for what the fill cannot
reach, then typed links between nodes. Links are walk, jump, crouch jump, drop,
crouch, ladder up and down, door and teleport, and `traverse.qc` executes each
one by writing `.velocity`. Half-Life nodes, when a map has them, seed the
generator and nothing more.

The graph is cached per map in `maps/bnav/<map>.bnav`, keyed by a crc16 of the
world surfaces, and is multiplayer only (a singleplayer save writes every edict,
and nodes are edicts). Humans teach it: `wp_learn.qc` watches where people walk
and jump and adds links the generator missed. `cmd wp` is an in-game editor;
edits are never overwritten by generation.

**Nodes are entities, not arrays.** DarkPlaces and Zircon have no array opcode
handlers, so fteqcc compiles a QC array into a binary search of statements per
access; a graph-sized array overflows the statement budget and makes every read
a function call. Do not add large QC arrays to the bot code.

## Decisions are scored

`utility.qc` scores roam, combat, cover, peek, flank, push, hunt and rearm from
the situation times the bot's own aggression and skill, with a bonus for
whatever it is already doing so it does not flip every tick. Aggression is
rolled independently of skill: skill decides whether a bot hits, aggression
decides whether it pushes or hides, so two bots of the same skill play
differently.

## Things that bite

* **Stuck is measured as progress toward the current hop**, not as raw movement,
  and escalates: probe and jump, back off, blacklist the link, abandon the goal,
  walk back to the last node reached cleanly.
* **Core limits two abilities for bots** and the bot code bypasses both from QC:
  `player/jump.qc` allows a bot one jump a second, and `func_ladder.qc` returns
  for `CLIENTTYPE_BOT`.
* **Recoil has to be decayed in QC.** The engine only decays `punchangle` while
  processing a real client's move packet, so an unmanaged bot walks its fire
  into the ceiling.
* **`.v_angle` on a bot stores pitch positive DOWN**, the convention every
  consumer of a player's angles expects. `Bot_LookAngles` is the one conversion
  point.
* **An observer reads as alive** (health 666, `DEAD_NO`), so every bot frame
  tests the classname first.

## Known gaps

Lifts and moving platforms are not modelled. The generator links walking,
jumping, crouching, drops, ladders, unnamed doors and teleports; a `func_plat`
or a `func_train` produces no link, so a map whose upper floors are reached by
a lift is only covered at ground level. Measured: `boot_camp` generates 3747
nodes with 11 ladder links and bots use them, while `crossfire`, whose tower is
a lift, generates 901 nodes with no ladder or door links and bots stall trying
to reach items above them. An item a bot cannot route to is dropped and
blacklisted for 30 seconds rather than walked at.

## Cvars and commands

| | |
| --- | --- |
| `cmd bot add [n]` / `remove [n]` / `kickall` | add or drop bots |
| `cmd bot debug` / `stuckstats` | per bot state, and stuck accounting |
| `cmd wp show\|stats\|near\|add\|del\|from\|to\|save\|load\|gen\|clear` | the waypoint editor |
| `bot_count` | how many bots the balancer keeps |
| `bot_skill` | 0..1 baseline; each bot rolls this plus or minus 0.2 |
| `bot_prefix` | netname prefix, default `[BOT] ` |
| `bot_physics` | 1 velocity (default), 2 movement, 3 standard physics, 0 self measuring |
| `bot_wp_autogen` / `bot_wp_genrate` / `bot_wp_save` / `bot_wp_learn` | graph generation, its tick budget, the cache, and learning from humans |

QUALKER keeps its own copy of this system, integrated with teams, the downed
state and the trader, so core's is dropped from that build (`tools/drops.txt`)
and `serverqc/bot_shim.qc` points core's two hooks at the QUALKER bots.
