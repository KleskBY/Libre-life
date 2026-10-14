// Waypoint generation from the map itself, spread across frames.
//
// Five phases, each resumable, each spending at most bot_wp_genrate trace
// operations per generator think so a large map never hitches the server and
// never approaches the engine's runaway limit:
//
//   seed     spawn points, items, and imported Half-Life info_nodes
//   flood    walk a player hull outward from every node in 8 directions,
//            classifying what stops it: a step it can climb, a crouch
//            passage, a ledge it can jump onto, a drop, a gap
//   entities ladders get up and down links, teleporters a one way link
//   surfaces walkable world faces the flood never reached become islands,
//            which the flood then tries to connect with jumps and drops
//   reach    flood from the seeds over links; anything unreached is an orphan,
//            kept for routing but never chosen as a roam goal
//
// Only reachable space is ever filled from the seeds, so roofs and the outside
// of the map stay empty unless a surface island turns out to connect.

#define WPG_SPACING   96
#define WPG_STEP      32
#define WPG_STEPUP    18
#define WPG_JUMP      42      // plain jump apex is 45.6: keep a margin
#define WPG_CJUMP     60      // with the air duck hull lift
#define WPG_DROP      200     // fall damage starts at 210
#define WPG_GAP       128
#define WPG_MERGE     56      // a candidate this close to a node reuses it

#define WPG_IDLE      0
#define WPG_SEED      1
#define WPG_FLOOD     2
#define WPG_ENTS      3
#define WPG_SURF      4
#define WPG_REACH     5
#define WPG_DONE      6

#define WPGS_OK       0
#define WPGS_BLOCKED  1
#define WPGS_LEDGE    2
#define WPGS_BAD      3

.entity wpg_qNext;

float  wpg_state;
float  wpg_after;        // phase to run once the flood queue drains
float  wpg_ops;
float  wpg_budget;
float  wpg_surf;
float  wpg_startTime;
entity wpg_cursor;
entity wpg_qHead;
entity wpg_qTail;
vector wpg_placed;
vector wpgs_end;
entity wpgs_door;
float  wpg_inherit;     // WPN_ISLAND while expanding an island, so it spreads to what it makes
float  wpg_islands;
vector wpg_bbMin;
vector wpg_bbMax;

void WP_Save();

float WPG_Active()
{
	return wpg_state != WPG_IDLE && wpg_state != WPG_DONE;
}

float WPG_Box(vector a, vector mn, vector mx, vector b, entity ignore)
{
	wpg_ops = wpg_ops + 1;
	tracebox(a, mn, mx, b, WP_NOMON, ignore);
	return trace_fraction;
}

void WPG_Enqueue(entity n)
{
	if (n.wp_flags & WPN_EXPANDED) return;
	n.wpg_qNext = world;
	if (wpg_qTail) wpg_qTail.wpg_qNext = n;
	else           wpg_qHead = n;
	wpg_qTail = n;
}

entity WPG_Dequeue()
{
	entity n = wpg_qHead;
	if (!n) return world;
	wpg_qHead = n.wpg_qNext;
	if (!wpg_qHead) wpg_qTail = world;
	n.wpg_qNext = world;
	return n;
}

float WPG_InHurt(vector p)
{
	wpg_ops = wpg_ops + 1;
	for (entity e = findbox(p + PLAYER_STAND_SIZE_MIN, p + PLAYER_STAND_SIZE_MAX); e; e = e.chain)
		if (e.classname == "trigger_hurt") return TRUE;
	return FALSE;
}

// Stand a player hull on the floor under p, within `drop`. Sets wpg_placed.
float WPG_Place(vector p, float drop)
{
	vector mn = PLAYER_STAND_SIZE_MIN;
	vector mx = PLAYER_STAND_SIZE_MAX;

	WPG_Box(p, mn, mx, p - [0, 0, drop], world);
	if (trace_startsolid)
	{
		p_z = p_z + 24;
		WPG_Box(p, mn, mx, p - [0, 0, drop + 24], world);
		if (trace_startsolid) return FALSE;
	}
	if (trace_fraction == 1) return FALSE;
	if (trace_plane_normal_z < 0.7) return FALSE;

	vector e = trace_endpos;
	if (WP_BadContents(e + [0, 0, mn_z + 2])) return FALSE;
	if (pointcontents(e) == CONTENT_WATER) return FALSE;
	if (WPG_InHurt(e)) return FALSE;

	wpg_placed = e;
	return TRUE;
}

entity WPG_NodeAt(vector e, float flags)
{
	entity n = WP_NearestRaw(e, WPG_MERGE, 28);
	if (n) return n;
	flags = flags | wpg_inherit;
	n = WP_AddNode(e, flags);
	if (!n) return n;
	if (flags & WPN_ISLAND) wpg_islands = wpg_islands + 1;
	WPG_Enqueue(n);
	return n;
}

float WPG_IsUnnamedDoor(entity e)
{
	if (!e) return FALSE;
	if (e.targetname != "") return FALSE;
	return (e.classname == "func_door" || e.classname == "func_door_rotating");
}

// Walk a hull `dist` along a flat `dir`, stepping up to WPG_STEPUP and down to a
// floor, the way player physics would. Sets wpgs_end to the last good point and
// wpgs_door to an unnamed door it had to pass through.
float WPG_Walk(vector from, vector dir, float dist, vector mn, vector mx)
{
	vector p = from;
	float left = dist;
	entity ign = world;
	wpgs_door = world;

	while (left > 0)
	{
		float s = WPG_STEP;
		if (left < s) s = left;
		vector ahead = p + dir * s;

		WPG_Box(p, mn, mx, ahead, ign);
		if (trace_fraction < 1 && WPG_IsUnnamedDoor(trace_ent))
		{
			wpgs_door = trace_ent;
			ign = trace_ent;
			WPG_Box(p, mn, mx, ahead, ign);
		}

		if (trace_fraction < 1)
		{
			WPG_Box(p, mn, mx, p + [0, 0, WPG_STEPUP], ign);
			if (trace_fraction < 1) { wpgs_end = p; return WPGS_BLOCKED; }
			vector up = trace_endpos;
			WPG_Box(up, mn, mx, up + dir * s, ign);
			if (trace_fraction < 1) { wpgs_end = p; return WPGS_BLOCKED; }
		}
		ahead = trace_endpos;

		WPG_Box(ahead, mn, mx, ahead - [0, 0, WPG_STEPUP + 18], ign);
		if (trace_fraction == 1) { wpgs_end = ahead; return WPGS_LEDGE; }
		if (trace_plane_normal_z < 0.7) { wpgs_end = p; return WPGS_BAD; }

		p = trace_endpos;
		if (WP_BadContents(p + [0, 0, mn_z + 2])) { wpgs_end = p; return WPGS_BAD; }
		if (pointcontents(p) == CONTENT_WATER) { wpgs_end = p; return WPGS_BAD; }
		left = left - s;
	}

	wpgs_end = p;
	return WPGS_OK;
}

// A passage that only a ducked hull fits: walk it crouched until a standing
// hull fits again.
float WPG_TryCrouch(entity n, vector edge, vector dir)
{
	vector p = edge;
	for (float i = 0; i < 6; i = i + 1)
	{
		if (WPG_Walk(p, dir, WPG_STEP, PLAYER_DUCK_SIZE_MIN, PLAYER_DUCK_SIZE_MAX) != WPGS_OK)
			return FALSE;
		p = wpgs_end;

		WPG_Box(p, PLAYER_STAND_SIZE_MIN, PLAYER_STAND_SIZE_MAX, p, world);
		if (trace_startsolid) continue;
		if (i == 0) return FALSE;    // fitted straight away: a plain block, not a crouch

		entity m = WPG_NodeAt(p, 0);
		if (!m || m == n) return FALSE;
		WP_AddLink(n, m, WPL_CROUCH, 0, 0);
		WP_AddLink(m, n, WPL_CROUCH, 0, 0);
		return TRUE;
	}
	return FALSE;
}

float WPG_TryJumpUp(entity n, vector edge, vector dir)
{
	for (float pass = 0; pass < 2; pass = pass + 1)
	{
		float h = (pass == 0) ? WPG_JUMP : WPG_CJUMP;
		vector mn = PLAYER_STAND_SIZE_MIN;
		vector mx = PLAYER_STAND_SIZE_MAX;
		if (pass == 1) { mn = PLAYER_DUCK_SIZE_MIN; mx = PLAYER_DUCK_SIZE_MAX; }

		WPG_Box(edge, mn, mx, edge + [0, 0, h], world);
		if (trace_fraction < 1) continue;
		vector up = trace_endpos;

		WPG_Box(up, mn, mx, up + dir * 40, world);
		if (trace_fraction < 1) continue;

		if (!WPG_Place(trace_endpos + '0 0 8', h + 16)) continue;
		if (wpg_placed_z - edge_z <= WPG_STEPUP) continue;

		entity m = WPG_NodeAt(wpg_placed, 0);
		if (!m || m == n) return FALSE;
		WP_AddLink(n, m, (pass == 0) ? WPL_JUMP : WPL_CROUCHJUMP, 0, 0);
		WP_AddLink(m, n, WPL_DROP, 0, 0);
		return TRUE;
	}
	return FALSE;
}

float WPG_TryDrop(entity n, vector lip, vector dir)
{
	WPG_Box(lip, PLAYER_STAND_SIZE_MIN, PLAYER_STAND_SIZE_MAX, lip + dir * 16, world);
	if (trace_fraction < 1) return FALSE;
	vector out = trace_endpos;

	if (!WPG_Place(out, WPG_DROP + 24)) return FALSE;
	float dz = lip_z - wpg_placed_z;
	if (dz <= WPG_STEPUP || dz > WPG_DROP) return FALSE;

	entity m = WPG_NodeAt(wpg_placed, 0);
	if (!m || m == n) return FALSE;
	WP_AddLink(n, m, WPL_DROP, 0, 0);

	// The way back up, when a hull fits the climb. This is what connects a
	// surface island (a crate top, a ledge) the flood below never reached.
	if (dz <= WPG_CJUMP)
	{
		vector up = m.origin + [0, 0, dz + 8];
		WPG_Box(m.origin, PLAYER_DUCK_SIZE_MIN, PLAYER_DUCK_SIZE_MAX, up, world);
		if (trace_fraction == 1)
		{
			WPG_Box(up, PLAYER_DUCK_SIZE_MIN, PLAYER_DUCK_SIZE_MAX, [n.origin_x, n.origin_y, up_z], world);
			if (trace_fraction == 1)
				WP_AddLink(m, n, (dz <= WPG_JUMP) ? WPL_JUMP : WPL_CROUCHJUMP, 0, 0);
		}
	}
	return TRUE;
}

float WPG_TryGap(entity n, vector lip, vector dir)
{
	vector a = lip + '0 0 24';
	WPG_Box(lip, PLAYER_STAND_SIZE_MIN, PLAYER_STAND_SIZE_MAX, a, world);
	if (trace_fraction < 1) return FALSE;

	for (float g = 64; g <= WPG_GAP; g = g + 32)
	{
		WPG_Box(a, PLAYER_STAND_SIZE_MIN, PLAYER_STAND_SIZE_MAX, a + dir * g, world);
		if (trace_fraction < 1) return FALSE;
		if (!WPG_Place(trace_endpos, 24 + WPG_STEPUP + 16)) continue;
		if (fabs(wpg_placed_z - lip_z) > 32) continue;

		entity m = WPG_NodeAt(wpg_placed, 0);
		if (!m || m == n) return FALSE;
		WP_AddLink(n, m, WPL_JUMP, 0, 0);
		return TRUE;
	}
	return FALSE;
}

void WPG_Expand(entity n)
{
	n.wp_flags = n.wp_flags | WPN_EXPANDED;
	vector o = n.origin;

	// An island only reaches what already exists by walking; it never floods.
	// Walkable faces outside the playable space would otherwise fill the budget.
	wpg_inherit = n.wp_flags & WPN_ISLAND;

	for (float i = 0; i < 8; i = i + 1)
	{
		makevectors([0, i * 45, 0]);
		vector dir = v_forward;
		dir_z = 0;

		float r = WPG_Walk(o, dir, WPG_SPACING, PLAYER_STAND_SIZE_MIN, PLAYER_STAND_SIZE_MAX);
		if (r == WPGS_OK)
		{
			entity door = wpgs_door;
			entity m = wpg_inherit ? WP_NearestRaw(wpgs_end, WPG_MERGE, 28) : WPG_NodeAt(wpgs_end, 0);
			if (m && m != n)
			{
				float t = door ? WPL_DOOR : WPL_WALK;
				float en = door ? num_for_edict(door) : 0;
				WP_AddLink(n, m, t, 0, en);
				WP_AddLink(m, n, t, 0, en);
			}
		}
		else if (r == WPGS_BLOCKED)
		{
			vector edge = wpgs_end;
			if (!WPG_TryCrouch(n, edge, dir))
				WPG_TryJumpUp(n, edge, dir);
		}
		else if (r == WPGS_LEDGE)
		{
			vector lip = wpgs_end;
			if (!WPG_TryDrop(n, lip, dir))
				WPG_TryGap(n, lip, dir);
		}

		if (wp_count >= WP_MAX) return;
	}
}

void WPG_Ladder(entity lad)
{
	vector mn = lad.absmin;
	vector mx = lad.absmax;
	vector c = (mn + mx) * 0.5;
	entity bottom = world;
	entity top = world;

	for (float i = 0; i < 4; i = i + 1)
	{
		makevectors([0, i * 90, 0]);
		vector dir = v_forward;
		float half = (fabs(dir_x) > 0.5) ? (mx_x - mn_x) * 0.5 : (mx_y - mn_y) * 0.5;

		if (!bottom)
		{
			if (WPG_Place([c_x, c_y, mn_z + 40] + dir * (half + 20), 80))
				if (wpg_placed_z < mn_z + 64) bottom = WPG_NodeAt(wpg_placed, 0);
		}
		if (!top)
		{
			if (WPG_Place([c_x, c_y, mx_z + 48] + dir * (half + 24), 80))
				if (wpg_placed_z > mx_z - 16 && wpg_placed_z < mx_z + 72) top = WPG_NodeAt(wpg_placed, 0);
		}
	}

	if (!bottom || !top || bottom == top) return;
	float en = num_for_edict(lad);
	WP_AddLink(bottom, top, WPL_LADDER_UP, 0, en);
	WP_AddLink(top, bottom, WPL_LADDER_DOWN, 0, en);
}

void WPG_Teleport(entity tp)
{
	if (tp.target == "") return;
	entity dst = find(world, targetname, tp.target);
	if (!dst) return;

	vector c = (tp.absmin + tp.absmax) * 0.5;
	if (!WPG_Place(c, (tp.absmax_z - tp.absmin_z) + 64)) return;
	entity a = WPG_NodeAt(wpg_placed, 0);

	if (!WPG_Place(dst.origin + '0 0 16', 128)) return;
	entity b = WPG_NodeAt(wpg_placed, 0);

	if (a && b && a != b) WP_AddLink(a, b, WPL_TELEPORT, 0, num_for_edict(tp));
}

// Half-Life info_nodes seed the regions no spawn point reaches. Their own links
// are not copied: the flood rebuilds them with typed, verified links.
void WPG_ImportCore()
{
	if (!node_graph_present || node_count <= 0) return;
	float total = node_count;
	if (total > NODE_MAX) total = NODE_MAX;

	for (float i = 0; i < total; i = i + 1)
	{
		if (node_realm[i] != NODE_REALM_LAND) continue;
		vector o = node_origin[i];     // own statement: the fteqcc vector array codegen bug
		if (WPG_Place(o + '0 0 36', 96)) WPG_NodeAt(wpg_placed, WPN_SEED);
	}
}

float WPG_IsSeedEntity(entity e)
{
	if (e.wp_isNode) return FALSE;
	if (substring(e.classname, 0, 11) == "info_player") return TRUE;
	if (substring(e.classname, 0, 8) == "team_CTF") return TRUE;
	if (e.item) return TRUE;
	if (substring(e.classname, 0, 7) == "weapon_") return TRUE;
	if (substring(e.classname, 0, 5) == "item_") return TRUE;
	if (substring(e.classname, 0, 5) == "ammo_") return TRUE;
	return FALSE;
}

void WPG_SeedStep()
{
	while (wpg_ops < wpg_budget)
	{
		wpg_cursor = nextent(wpg_cursor);
		if (!wpg_cursor)
		{
			wpg_after = WPG_ENTS;
			wpg_state = WPG_FLOOD;
			return;
		}
		if (!WPG_IsSeedEntity(wpg_cursor)) continue;
		if (WPG_Place(wpg_cursor.origin + '0 0 16', 128))
			WPG_NodeAt(wpg_placed, WPN_SEED);
	}
}

void WPG_FloodStep()
{
	while (wpg_ops < wpg_budget)
	{
		if (wp_count >= WP_MAX) { wpg_qHead = wpg_qTail = world; }
		entity n = WPG_Dequeue();
		if (!n)
		{
			wpg_state = wpg_after;
			return;
		}
		if (n.wp_flags & (WPN_DEAD | WPN_EXPANDED)) continue;
		WPG_Expand(n);
		wpg_inherit = 0;
	}
}

void WPG_EntitiesStep()
{
	for (entity e = find(world, classname, "func_ladder"); e; e = find(e, classname, "func_ladder"))
		WPG_Ladder(e);
	for (entity t = find(world, classname, "trigger_teleport"); t; t = find(t, classname, "trigger_teleport"))
		WPG_Teleport(t);

	// Islands only inside the space the flood actually reached, padded.
	wpg_bbMin = '99999 99999 99999';
	wpg_bbMax = '-99999 -99999 -99999';
	for (entity n = wp_first; n; n = n.wp_allNext)
	{
		if (n.origin_x < wpg_bbMin_x) wpg_bbMin_x = n.origin_x;
		if (n.origin_y < wpg_bbMin_y) wpg_bbMin_y = n.origin_y;
		if (n.origin_z < wpg_bbMin_z) wpg_bbMin_z = n.origin_z;
		if (n.origin_x > wpg_bbMax_x) wpg_bbMax_x = n.origin_x;
		if (n.origin_y > wpg_bbMax_y) wpg_bbMax_y = n.origin_y;
		if (n.origin_z > wpg_bbMax_z) wpg_bbMax_z = n.origin_z;
	}
	wpg_bbMin = wpg_bbMin - '256 256 256';
	wpg_bbMax = wpg_bbMax + '256 256 256';

	wpg_surf = 0;
	wpg_islands = 0;
	wpg_after = WPG_SURF;
	wpg_state = WPG_FLOOD;
}

void WPG_SurfStep()
{
	while (wpg_ops < wpg_budget)
	{
		float np = getsurfacenumpoints(world, wpg_surf);
		if (np <= 0 || wp_count >= WP_MAX * 0.85 || wpg_islands >= WP_MAX * 0.2)
		{
			wpg_after = WPG_REACH;
			wpg_state = WPG_FLOOD;
			return;
		}
		float s = wpg_surf;
		wpg_surf = wpg_surf + 1;
		wpg_ops = wpg_ops + 1;

		vector nrm = getsurfacenormal(world, s);
		if (nrm_z < 0.7) continue;
		if (strstrofs(getsurfacetexture(world, s), "sky", 0) >= 0) continue;

		float k = np;
		if (k > 16) k = 16;
		vector sum = '0 0 0';
		for (float i = 0; i < k; i = i + 1)
			sum = sum + getsurfacepoint(world, s, i);
		vector cen = sum * (1 / k);
		wpg_ops = wpg_ops + 2;

		if (cen_x < wpg_bbMin_x || cen_y < wpg_bbMin_y || cen_z < wpg_bbMin_z) continue;
		if (cen_x > wpg_bbMax_x || cen_y > wpg_bbMax_y || cen_z > wpg_bbMax_z) continue;

		if (WP_NearestRaw(cen + '0 0 24', 128, 64)) continue;
		if (!WPG_Place(cen + nrm * 2 + '0 0 48', 72)) continue;
		if (WP_NearestRaw(wpg_placed, 96, 48)) continue;
		WPG_NodeAt(wpg_placed, WPN_ISLAND);
	}
}

// Everything reachable from a seed over links is part of the map; the rest are
// orphans.
void WPG_ReachStep()
{
	entity n;
	for (n = wp_first; n; n = n.wp_allNext)
		n.wp_flags = n.wp_flags | WPN_ORPHAN;

	wpg_qHead = wpg_qTail = world;
	for (n = wp_first; n; n = n.wp_allNext)
	{
		if (!(n.wp_flags & WPN_SEED) && !(n.wp_flags & WPN_EDITED)) continue;
		if (n.wp_flags & WPN_DEAD) continue;
		n.wp_flags = n.wp_flags - (n.wp_flags & WPN_ORPHAN);
		n.wpg_qNext = world;
		if (wpg_qTail) wpg_qTail.wpg_qNext = n; else wpg_qHead = n;
		wpg_qTail = n;
	}

	while ((n = WPG_Dequeue()))
	{
		for (float s = 0; s < WP_LINKS; s = s + 1)
		{
			if (!WPL_Usable(n, s)) continue;
			entity d = WPL_Dest(n, s);
			if (!(d.wp_flags & WPN_ORPHAN)) continue;
			d.wp_flags = d.wp_flags - WPN_ORPHAN;
			d.wpg_qNext = world;
			if (wpg_qTail) wpg_qTail.wpg_qNext = d; else wpg_qHead = d;
			wpg_qTail = d;
		}
	}

	// Unreachable islands are useless to a bot and cost budget and every full
	// entity scan. Doomed nodes are marked first, links into them cleared from the
	// survivors, and only then freed, so a reused edict never inherits a link.
	for (n = wp_first; n; n = n.wp_allNext)
		if ((n.wp_flags & WPN_ORPHAN) && (n.wp_flags & WPN_ISLAND))
			if (!(n.wp_flags & (WPN_EDITED | WPN_HUMAN))) n.wp_isNode = FALSE;

	for (n = wp_first; n; n = n.wp_allNext)
	{
		if (!n.wp_isNode) continue;
		for (float t = 0; t < WP_LINKS; t = t + 1)
		{
			entity to = WPL_Dest(n, t);
			if (to && !to.wp_isNode) WP_RemoveLink(n, t);
		}
	}

	entity prevN = world;
	n = wp_first;
	while (n)
	{
		entity nx = n.wp_allNext;
		if (!n.wp_isNode)
		{
			if (prevN) prevN.wp_allNext = nx;
			else       wp_first = nx;
			wp_count = wp_count - 1;
			remove(n);
		}
		else
		{
			prevN = n;
		}
		n = nx;
	}

	wp_linkCount = 0;
	float orphans = 0;
	for (n = wp_first; n; n = n.wp_allNext)
	{
		if (n.wp_flags & WPN_ORPHAN) orphans = orphans + 1;
		for (float u = 0; u < WP_LINKS; u = u + 1)
			if (WPL_Dest(n, u)) wp_linkCount = wp_linkCount + 1;
	}
	WP_GridRebuild();

	wpg_state = WPG_DONE;
	print(strcat("waypoints: generated ", ftos(wp_count), " nodes, ", ftos(wp_linkCount), " links"));
	print(strcat(", ", ftos(orphans), " unreachable, in ", ftos(rint(time - wpg_startTime)), "s\n"));
	if (cvar("bot_wp_save")) WP_Save();
}

// Remove everything the generator or learning made, keeping hand edits and the
// links between them. Links are cleared BEFORE any entity is freed, so a reused
// edict can never become the target of a stale link.
void WP_ClearGenerated()
{
	entity n;
	for (n = wp_first; n; n = n.wp_allNext)
	{
		if (!(n.wp_flags & WPN_EDITED)) continue;
		for (float s = 0; s < WP_LINKS; s = s + 1)
		{
			entity d = WPL_Dest(n, s);
			if (!d) continue;
			float keep = (d.wp_flags & WPN_EDITED) && !(d.wp_flags & WPN_DEAD)
			             && (WPC_Flags(WPL_Code(n, s)) & WPLF_EDITED);
			if (!keep) WP_RemoveLink(n, s);
		}
	}

	n = wp_first;
	wp_first = world;
	wp_count = 0;
	while (n)
	{
		entity nx = n.wp_allNext;
		if ((n.wp_flags & WPN_EDITED) && !(n.wp_flags & WPN_DEAD))
		{
			n.wp_allNext = wp_first;
			wp_first = n;
			wp_count = wp_count + 1;
		}
		else
		{
			n.wp_isNode = FALSE;
			remove(n);
		}
		n = nx;
	}

	wp_linkCount = 0;
	for (n = wp_first; n; n = n.wp_allNext)
		for (float t = 0; t < WP_LINKS; t = t + 1)
			if (WPL_Dest(n, t)) wp_linkCount = wp_linkCount + 1;

	WP_GridRebuild();
	wp_dirty = TRUE;
}

void WPG_Start(float keepEdited)
{
	if (keepEdited) WP_ClearGenerated();
	else            WP_Clear();

	wpg_qHead = wpg_qTail = world;
	for (entity n = wp_first; n; n = n.wp_allNext)
	{
		n.wp_flags = n.wp_flags - (n.wp_flags & WPN_EXPANDED);
		WPG_Enqueue(n);
	}

	wpg_ops = 0;
	WPG_ImportCore();

	wpg_cursor = world;
	wpg_surf = 0;
	wpg_state = WPG_SEED;
	wpg_startTime = time;
	print("waypoints: generating from the map, bots will improve as it fills in\n");
}

void WPG_Step()
{
	if (!WPG_Active()) return;

	wpg_budget = cvar("bot_wp_genrate");
	if (wpg_budget < 50) wpg_budget = 300;
	wpg_ops = 0;

	if (wpg_state == WPG_SEED)       WPG_SeedStep();
	else if (wpg_state == WPG_FLOOD) WPG_FloodStep();
	else if (wpg_state == WPG_ENTS)  WPG_EntitiesStep();
	else if (wpg_state == WPG_SURF)  WPG_SurfStep();
	else if (wpg_state == WPG_REACH) WPG_ReachStep();
}
