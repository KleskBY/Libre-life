// Learning waypoints from how human players actually move.
//
// The generator reads the map; people find the jumps and shortcuts it misses.
// Every human is sampled a few times a second: which node they last stood on,
// whether they left the ground, how high they rose, whether they crouched, rode
// a ladder, or were teleported. Landing on a different node with no link between
// the two turns that record into a typed link.
//
// A special link needs two sightings before it is trusted, so one lucky
// bunny-hop does not teach every bot to throw itself off a ledge. A walk link is
// verified with the generator's own hull walker instead. A teleport is taken on
// one sighting: nothing else moves a player a few hundred units in a tenth of a
// second.
//
// Standing somewhere far from every node adds a node there, so coverage grows
// toward where people actually go.

#define WPLN_SAMPLE   0.1
#define WPLN_SNAP     64     // standing this close to a node counts as on it
#define WPLN_NEW      110    // further than this from every node adds one
#define WPLN_PENDING  32

nosave entity wpln_a[WPLN_PENDING];
nosave entity wpln_b[WPLN_PENDING];
nosave float  wpln_type[WPLN_PENDING];
float wpln_next;

// TRUE on the second sighting of the same link.
float WPLN_Observe(entity a, entity b, float type)
{
	for (float i = 0; i < WPLN_PENDING; i = i + 1)
	{
		if (wpln_a[i] != a) continue;
		if (wpln_b[i] != b) continue;
		if (wpln_type[i] != type) continue;
		wpln_a[i] = world;
		return TRUE;
	}

	float slot = wpln_next;
	wpln_next = wpln_next + 1;
	if (wpln_next >= WPLN_PENDING) wpln_next = 0;
	wpln_a[slot] = a;
	wpln_b[slot] = b;
	wpln_type[slot] = type;
	return FALSE;
}

entity WPLN_LadderAt(entity p)
{
	for (entity e = find(world, classname, "func_ladder"); e; e = find(e, classname, "func_ladder"))
		if (Bot_InBox(p, e, 8)) return e;
	return world;
}

void WPLN_Record(entity p, entity prev, entity n)
{
	float dz = n.origin_z - prev.origin_z;
	float flat = Bot_FlatDist(prev.origin, n.origin);
	float type = WPL_WALK;
	float ent = 0;

	if (p.bot_learnLadder)
	{
		type = (dz > 0) ? WPL_LADDER_UP : WPL_LADDER_DOWN;
		ent = p.bot_learnLadder - 1;
	}
	else if (p.bot_learnAir)
	{
		float rise = p.bot_learnPeakZ - p.bot_learnStartZ;
		if (dz > WPG_STEPUP)       type = p.bot_learnCrouch ? WPL_CROUCHJUMP : WPL_JUMP;
		else if (dz < -WPG_STEPUP) type = WPL_DROP;
		else if (rise > 24)        type = WPL_JUMP;
	}
	else if (p.crouching)
	{
		type = WPL_CROUCH;
	}

	float maxFlat = 420;
	if (type == WPL_WALK || type == WPL_CROUCH) maxFlat = 200;
	if (p.bot_learnLadder) maxFlat = 160;
	if (flat > maxFlat) return;

	float s = WP_FindSlot(prev, n);
	if (s >= 0)
	{
		// Somebody just did what the link says: it works, whatever the bots
		// have been reporting. Re-enables a link failures switched off.
		WP_LinkSucceeded(WPL_Id(prev, s));
		if (WPC_Flags(WPL_Code(prev, s)) & WPLF_DISABLED)
			WP_AddLink(prev, n, WPC_Type(WPL_Code(prev, s)), WPLF_LEARNED, WPC_Ent(WPL_Code(prev, s)));
		return;
	}

	if (type == WPL_WALK)
	{
		vector dir = n.origin - prev.origin;
		dir_z = 0;
		if (vlen(dir) < 1) return;
		dir = normalize(dir);
		if (WPG_Walk(prev.origin, dir, flat, PLAYER_STAND_SIZE_MIN, PLAYER_STAND_SIZE_MAX) != WPGS_OK) return;
		if (Bot_FlatDist(wpgs_end, n.origin) > 40) return;
		WP_AddLink(prev, n, WPL_WALK, WPLF_LEARNED, 0);
		WP_AddLink(n, prev, WPL_WALK, WPLF_LEARNED, 0);
		return;
	}

	if (WPLN_Observe(prev, n, type))
		WP_AddLink(prev, n, type, WPLF_LEARNED, ent);
}

void WP_LearnFrame(entity p)
{
	if (!WP_Ready() || WPG_Active()) return;
	if (!cvar("bot_wp_learn")) return;
	if (p.bot_isBot) return;
	if (p.classname != "player") return;
	if (!IsAlive(p) || p.bot_down) return;
	if (p.movetype == MOVETYPE_NOCLIP) return;
	if (time < p.bot_learnAt) return;
	p.bot_learnAt = time + WPLN_SAMPLE;

	vector o = p.origin;

	if (p.bot_learnLastOrg != '0 0 0' && vlen(o - p.bot_learnLastOrg) > 256)
	{
		entity from = p.bot_learnNode;
		entity to = WP_NearestRaw(o, WPLN_SNAP, 48);
		if (WP_Live(from) && to && from != to)
			WP_AddLink(from, to, WPL_TELEPORT, WPLF_LEARNED, 0);
		p.bot_learnLastOrg = o;
		p.bot_learnNode = to;
		p.bot_learnAir = FALSE;
		p.bot_learnLadder = 0;
		return;
	}
	p.bot_learnLastOrg = o;

	if (p.movetype == MOVETYPE_FLY)
	{
		entity lad = WPLN_LadderAt(p);
		if (lad) p.bot_learnLadder = num_for_edict(lad) + 1;
	}

	if (!(p.flags & FL_ONGROUND))
	{
		if (!p.bot_learnAir)
		{
			p.bot_learnAir = TRUE;
			p.bot_learnStartZ = o_z;
			p.bot_learnPeakZ = o_z;
			p.bot_learnCrouch = FALSE;
		}
		if (o_z > p.bot_learnPeakZ) p.bot_learnPeakZ = o_z;
		if (p.button3 || p.crouching) p.bot_learnCrouch = TRUE;
		return;
	}

	entity n = WP_NearestRaw(o, WPLN_SNAP, 40);
	if (!n)
	{
		if (WP_NearestRaw(o, WPLN_NEW, 64)) return;    // between nodes, keep the record running
		if (!WPG_Place(o + '0 0 8', 32)) return;
		n = WP_AddNode(wpg_placed, WPN_HUMAN);
		if (!n) return;
	}

	entity prev = p.bot_learnNode;
	if (WP_Live(prev) && prev != n) WPLN_Record(p, prev, n);

	p.bot_learnNode = n;
	p.bot_learnAir = FALSE;
	p.bot_learnLadder = 0;
	p.bot_learnCrouch = FALSE;
}
