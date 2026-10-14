// Cooperative item ownership.
//
// In coop an item has to be consumable once per player: it must vanish and stop
// responding for whoever took it, while staying visible and pickable for
// everyone who hasn't. Solidity is global on the server, so this is split in
// two:
//
// the map's item entity becomes an invisible MASTER, keeping its trigger
//     bbox and all the touch logic, and records which client slots have already
//     consumed it in a bitmask.
//   * a cosmetic GHOST is spawned per player, SOLID_NOT and pinned to that
//     client with the engine's .drawonlytoclient field. Taking the item removes
//     only that player's ghost.
//
// Ghosts are event-driven; they are rebuilt when a player spawns and dropped when they leave
// leave, so there is no polling.

float Player_SlotIndex(entity p);	// player/spawnpoint.qc

#define COOPITEM_GHOST "coop_item_ghost"

// Bits are client slots; coop is capped well below the float mantissa limit.
#define COOPITEM_MAX_SLOTS 24

.float  coopIsMaster;     // master: this item uses per-player ownership
.float  coopTakenBits;    // master: bitmask of client slots that consumed it
.entity coopMaster;       // ghost -> the master it mirrors
.entity coopOwner;        // ghost -> the only client that can see it

float CoopItem_Enabled()
{
	return cvar("gamemode") == MODE_COOP;
}

float CoopItem_SlotBit(entity p)
{
	float slot = Player_SlotIndex(p);
	if (slot < 0 || slot >= COOPITEM_MAX_SLOTS) return 0;
	return pow(2, slot);
}

// TRUE when this player has already consumed the item and must be ignored.
float CoopItem_Taken(entity item, entity p)
{
	if (!item.coopIsMaster) return FALSE;
	float bit = CoopItem_SlotBit(p);
	if (!bit) return FALSE;
	return (item.coopTakenBits & bit) != 0;
}

void CoopItem_SpawnGhost(entity master, entity p)
{
	if (!master.mdl || master.mdl == "") return;

	entity g = spawn();
	g.classname  = COOPITEM_GHOST;
	g.coopMaster = master;
	g.coopOwner  = p;
	g.drawonlytoclient = p;

	g.movetype = MOVETYPE_NONE;
	g.solid    = SOLID_NOT;
	setmodel(g, master.mdl);
	// Match the master's bbox: the engine culls by size, and a zero-extent
	// box can drop the ghost out of the client's visible set.
	setsize(g, master.mins, master.maxs);
	setorigin(g, master.origin);
	g.angles = master.angles;
	g.skin   = master.skin;
	g.frame  = master.frame;
	g.scale  = master.scale;
	g.effects = master.effects;
}

void CoopItem_RemoveGhostsFor(entity p)
{
	entity g = findchain(classname, COOPITEM_GHOST);
	while (g)
	{
		entity next = g.chain;		// capture before remove
		if (g.coopOwner == p) remove(g);
		g = next;
	}
}

void CoopItem_RemoveGhost(entity master, entity p)
{
	entity g = findchain(classname, COOPITEM_GHOST);
	while (g)
	{
		entity next = g.chain;
		if (g.coopMaster == master && g.coopOwner == p) remove(g);
		g = next;
	}
}

// Converts a freshly-placed item into an invisible master, giving every player
// present their own copy. Called from Item_Place after droptofloor.
void CoopItem_MakeMaster(entity item)
{
	if (!CoopItem_Enabled()) return;
	if (item.coopIsMaster) return;

	item.coopIsMaster  = TRUE;
	item.coopTakenBits = 0;

	// Keep the trigger bbox; stop drawing the master itself by assigning the
	// fields directly rather than setmodel("") so setsize() survives.
	if (item.mdl == "") item.mdl = item.model;
	item.model      = "";
	item.modelindex = 0;

	for (entity p = find(world, classname, "player"); p; p = find(p, classname, "player"))
		CoopItem_SpawnGhost(item, p);
}

// Rebuilds a player's entire set of ghosts. Called at the end of
// PutClientInServer, so it covers first spawn, respawn and level arrival.
void CoopItem_RefreshFor(entity p)
{
	if (!CoopItem_Enabled()) return;
	if (!p || p.classname != "player") return;

	CoopItem_RemoveGhostsFor(p);

	float bit = CoopItem_SlotBit(p);
	for (entity m = findchainfloat(coopIsMaster, TRUE); m; m = m.chain)
	{
		if (bit && (m.coopTakenBits & bit)) continue;
		CoopItem_SpawnGhost(m, p);
	}
}

// This player just took the item: mark the slot and drop only their copy.
void CoopItem_Consume(entity master, entity p)
{
	float bit = CoopItem_SlotBit(p);
	if (bit) master.coopTakenBits = master.coopTakenBits | bit;
	CoopItem_RemoveGhost(master, p);
}
