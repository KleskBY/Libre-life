// Multiplayer spawn point selection.

float Player_SlotIndex(entity p)
{
	if (!p) return 0;
	float n = num_for_edict(p) - 1;
	if (n < 0) n = 0;
	return n;
}

// The spot must be triggerable by this player and free
// of other live players.
float SpawnPoint_IsValid(entity spot, entity pPlayer)
{
	if (!spot) return FALSE;
	if (spot.origin == '0 0 0') return FALSE;
	if (!Master_IsTriggered(spot.master, pPlayer)) return FALSE;

	for (entity e = findradius(spot.origin, 128); e; e = e.chain)
	{
		if (e == pPlayer) continue;
		if (e.classname != "player") continue;
		if (!IsAlive(e)) continue;
		return FALSE;
	}
	return TRUE;
}

// find() with a wrap back to the first entity of the class.
entity SpawnPoint_NextOfClass(entity from, string cls)
{
	entity e = find(from, classname, cls);
	if (!e && from) e = find(world, classname, cls);
	return e;
}

// Last resort when every spot is occupied: kill whoever is standing on it.
void SpawnPoint_Telefrag(entity spot, entity pPlayer)
{
	for (entity e = Chain_Freeze(findradius(spot.origin, 128)); e; e = e.dmg_chain)
	{
		if (e == pPlayer) continue;
		if (e.classname != "player") continue;
		if (!IsAlive(e)) continue;
		if (vlen(e.origin - spot.origin) > 128) continue;
		T_Damage(e, world, world, 300, DMG_GENERIC);
	}
}

entity SpawnPoint_SelectDM(entity pPlayer)
{
	entity spot = lastspawn;
	float tries = 10;

	if (!spot)
	{
		// First spawn of the map: bound the random advance by the real count.
		tries = 0;
		for (entity c = find(world, classname, "info_player_deathmatch"); c;
		     c = find(c, classname, "info_player_deathmatch"))
			tries = tries + 1;
	}
	if (tries < 1) tries = 1;

	for (float i = Math_RandomInt(1, tries) - 1; i > 0; i = i - 1)
		spot = find(spot, classname, "info_player_deathmatch");
	if (!spot)	// stepped off the end of the list
		spot = find(world, classname, "info_player_deathmatch");

	entity first = spot;
	while (spot)
	{
		if (SpawnPoint_IsValid(spot, pPlayer)) return spot;

		spot = SpawnPoint_NextOfClass(spot, "info_player_deathmatch");
		if (spot == first) break;
	}

	// A map with no deathmatch spots at all: the single player start beats the
	// world origin, which is where every arrival landed before.
	if (!first)
	{
		first = find(world, classname, "info_player_start");
		if (!first) first = find(world, classname, "info_player_coop");
		if (first) return first;
	}

	// Nothing free: telefrag onto the first spot rather than deadlock
	if (first)
	{
		SpawnPoint_Telefrag(first, pPlayer);
		return first;
	}
	return world;
}

entity SpawnPoint_SelectCoop(entity pPlayer)
{
	// The original system round-robins coop spots without a validity check, so a map with a
	// single info_player_coop still always spawns everyone.
	entity spot = SpawnPoint_NextOfClass(lastspawn, "info_player_coop");
	if (!spot) spot = SpawnPoint_NextOfClass(lastspawn, "info_player_start");
	if (!spot) spot = find(world, classname, "info_player_start");
	return spot;
}

float SpawnPoint_PlayerAt(vector org, entity pPlayer)
{
	for (entity e = findradius(org, 32); e; e = e.chain)
	{
		if (e == pPlayer) continue;
		if (e.classname != "player") continue;
		if (!IsAlive(e)) continue;
		return TRUE;
	}
	return FALSE;
}

// Coop lands everyone on the same spot, so nudge each arrival to nearby free
// space instead of letting the hulls interpenetrate. Rings outward so the team
// still spawns together.
vector SpawnPoint_FreeOriginNear(vector base, entity pPlayer)
{
	// Nobody in the way: keep the mapper's exact spot. The geometry test below
	// is only ever used to vet an offset; spawn points are often slightly
	// embedded and rely on the engine unsticking them, so it must never be a
	// reason to move the first player to arrive.
	if (!SpawnPoint_PlayerAt(base, pPlayer)) return base;

	for (float r = 32; r <= 96; r = r + 32)
	{
		for (float a = 0; a < 360; a = a + 45)
		{
			float rad = a * M_PI / 180;
			vector c = base + [cos(rad) * r, sin(rad) * r, 0];

			if (SpawnPoint_PlayerAt(c, pPlayer)) continue;

			tracebox(c, PLAYER_STAND_SIZE_MIN, PLAYER_STAND_SIZE_MAX, c, FALSE, pPlayer);
			if (trace_startsolid || trace_allsolid) continue;

			return c;
		}
	}
	return base;	// nowhere clear; let physics sort them out
}

// Where a player actually materialises for a given spot.
vector SpawnPoint_SpawnOrigin(entity spot, entity pPlayer)
{
	vector base = spot.origin + '0 0 1';
	// Deathmatch too: a map with one start hands every arrival the same spot.
	float gm = cvar("gamemode");
	if (gm != MODE_COOP && gm != MODE_DM) return base;
	return SpawnPoint_FreeOriginNear(base, pPlayer);
}

entity SelectSpawnPoint(entity pPlayer)
{
	float gm = cvar("gamemode");
	entity spot;

	if (gm == MODE_DM)
		spot = SpawnPoint_SelectDM(pPlayer);
	else if (gm == MODE_COOP)
		spot = SpawnPoint_SelectCoop(pPlayer);
	else
		spot = find(world, classname, "info_player_start");

	if (!spot)
	{
		dprint("SelectSpawnPoint: no spawn point on level\n");
		return world;
	}

	lastspawn = spot;

	// Fires the spot's target when a player spawns on it in multiplayer.
	if (gm != MODE_SP && spot.target)
		SUB_FireTargets(spot.target, pPlayer, pPlayer, USE_TOGGLE, 0);

	return spot;
}
