// The bot waypoint graph: nodes, typed links, and the spatial grid.
//
// NODES ARE ENTITIES, NOT ARRAY SLOTS. Zircon has no handler for the LOADA
// array opcodes, so fteqcc compiles every QC array into generated ArrayGet and
// ArraySet functions: a binary search of statements per array. Arrays sized for
// a navigation graph blew the statement budget and made every read a function
// call. Entity fields are plain field loads and cost neither globals nor
// statements.
//
// A node is never setorigin'd, so it is never linked into the world: findradius
// and every trace ignore it, and it has no model, so nothing is networked.
//
// Each node carries WP_LINKS out links in fixed fields. A link id is the node's
// edict number * 16 + slot; bot fields store it + 1 so 0 means none. A link's
// code packs type + flags * 16 + entity * 256.
//
// Separate from the core info_node graph (serverqc/ai/nodegraph.qc), which is
// only ever read, to import Half-Life nodes.

#define WP_MAX            4096
#define WP_LINKS          12
#define WP_GRID           1021    // prime bucket count for the cell hash
#define WP_CELL           128
#define WP_NOMON          1       // traceline nomonsters: world and brush entities only

#define WPL_WALK          0
#define WPL_JUMP          1
#define WPL_CROUCHJUMP    2
#define WPL_DROP          3
#define WPL_CROUCH        4
#define WPL_LADDER_UP     5
#define WPL_LADDER_DOWN   6
#define WPL_DOOR          7
#define WPL_TELEPORT      8
#define WPL_SWIM          9
#define WPL_TYPES         10

#define WPLF_DISABLED     1
#define WPLF_EDITED       2
#define WPLF_LEARNED      4

#define WPN_DEAD          1
#define WPN_EDITED        2
#define WPN_HUMAN         4
#define WPN_ISLAND        8
#define WPN_ORPHAN        16
#define WPN_EXPANDED      32
#define WPN_SEED          64

#define WPL_FAIL_DISABLE  6       // failures across all bots before a link is switched off

.float  wp_isNode;
.float  wp_flags;
.float  wp_id;              // sequential index, assigned at save and load
.entity wp_gridNext;
.entity wp_allNext;

.entity wpl_d0, wpl_d1, wpl_d2, wpl_d3, wpl_d4, wpl_d5, wpl_d6, wpl_d7, wpl_d8, wpl_d9, wpl_d10, wpl_d11;
.float  wpl_c0, wpl_c1, wpl_c2, wpl_c3, wpl_c4, wpl_c5, wpl_c6, wpl_c7, wpl_c8, wpl_c9, wpl_c10, wpl_c11;
.float  wpl_f0, wpl_f1, wpl_f2, wpl_f3, wpl_f4, wpl_f5, wpl_f6, wpl_f7, wpl_f8, wpl_f9, wpl_f10, wpl_f11;

nosave entity wp_grid[WP_GRID];
entity wp_first;
float  wp_count;
float  wp_linkCount;
float  wp_dirty;

float WP_Ready()
{
	return wp_count > 0;
}

float WP_Live(entity n)
{
	if (!n) return FALSE;
	if (!n.wp_isNode) return FALSE;
	return !(n.wp_flags & WPN_DEAD);
}

entity WPL_Dest(entity n, float s)
{
	if (s < 6)
	{
		if (s == 0) return n.wpl_d0;
		if (s == 1) return n.wpl_d1;
		if (s == 2) return n.wpl_d2;
		if (s == 3) return n.wpl_d3;
		if (s == 4) return n.wpl_d4;
		return n.wpl_d5;
	}
	if (s == 6) return n.wpl_d6;
	if (s == 7) return n.wpl_d7;
	if (s == 8) return n.wpl_d8;
	if (s == 9) return n.wpl_d9;
	if (s == 10) return n.wpl_d10;
	return n.wpl_d11;
}

void WPL_SetDest(entity n, float s, entity d)
{
	if (s < 6)
	{
		if (s == 0) n.wpl_d0 = d;
		else if (s == 1) n.wpl_d1 = d;
		else if (s == 2) n.wpl_d2 = d;
		else if (s == 3) n.wpl_d3 = d;
		else if (s == 4) n.wpl_d4 = d;
		else n.wpl_d5 = d;
		return;
	}
	if (s == 6) n.wpl_d6 = d;
	else if (s == 7) n.wpl_d7 = d;
	else if (s == 8) n.wpl_d8 = d;
	else if (s == 9) n.wpl_d9 = d;
	else if (s == 10) n.wpl_d10 = d;
	else n.wpl_d11 = d;
}

float WPL_Code(entity n, float s)
{
	if (s < 6)
	{
		if (s == 0) return n.wpl_c0;
		if (s == 1) return n.wpl_c1;
		if (s == 2) return n.wpl_c2;
		if (s == 3) return n.wpl_c3;
		if (s == 4) return n.wpl_c4;
		return n.wpl_c5;
	}
	if (s == 6) return n.wpl_c6;
	if (s == 7) return n.wpl_c7;
	if (s == 8) return n.wpl_c8;
	if (s == 9) return n.wpl_c9;
	if (s == 10) return n.wpl_c10;
	return n.wpl_c11;
}

void WPL_SetCodeRaw(entity n, float s, float c)
{
	if (s < 6)
	{
		if (s == 0) n.wpl_c0 = c;
		else if (s == 1) n.wpl_c1 = c;
		else if (s == 2) n.wpl_c2 = c;
		else if (s == 3) n.wpl_c3 = c;
		else if (s == 4) n.wpl_c4 = c;
		else n.wpl_c5 = c;
		return;
	}
	if (s == 6) n.wpl_c6 = c;
	else if (s == 7) n.wpl_c7 = c;
	else if (s == 8) n.wpl_c8 = c;
	else if (s == 9) n.wpl_c9 = c;
	else if (s == 10) n.wpl_c10 = c;
	else n.wpl_c11 = c;
}

float WPL_Fail(entity n, float s)
{
	if (s < 6)
	{
		if (s == 0) return n.wpl_f0;
		if (s == 1) return n.wpl_f1;
		if (s == 2) return n.wpl_f2;
		if (s == 3) return n.wpl_f3;
		if (s == 4) return n.wpl_f4;
		return n.wpl_f5;
	}
	if (s == 6) return n.wpl_f6;
	if (s == 7) return n.wpl_f7;
	if (s == 8) return n.wpl_f8;
	if (s == 9) return n.wpl_f9;
	if (s == 10) return n.wpl_f10;
	return n.wpl_f11;
}

void WPL_SetFail(entity n, float s, float v)
{
	if (s < 6)
	{
		if (s == 0) n.wpl_f0 = v;
		else if (s == 1) n.wpl_f1 = v;
		else if (s == 2) n.wpl_f2 = v;
		else if (s == 3) n.wpl_f3 = v;
		else if (s == 4) n.wpl_f4 = v;
		else n.wpl_f5 = v;
		return;
	}
	if (s == 6) n.wpl_f6 = v;
	else if (s == 7) n.wpl_f7 = v;
	else if (s == 8) n.wpl_f8 = v;
	else if (s == 9) n.wpl_f9 = v;
	else if (s == 10) n.wpl_f10 = v;
	else n.wpl_f11 = v;
}

float WPC_Type(float c)  { return c - floor(c / 16) * 16; }
float WPC_Flags(float c) { float v = floor(c / 16); return v - floor(v / 16) * 16; }
float WPC_Ent(float c)   { return floor(c / 256); }
float WPC_Make(float type, float flags, float ent) { return type + flags * 16 + ent * 256; }

float  WPL_Id(entity n, float s)  { return num_for_edict(n) * 16 + s; }
entity WPL_IdNode(float id)        { return edict_num(floor(id / 16)); }
float  WPL_IdSlot(float id)        { return id - floor(id / 16) * 16; }

// A slot that holds a live, enabled link.
float WPL_Usable(entity n, float s)
{
	if (!WP_Live(WPL_Dest(n, s))) return FALSE;
	return !(WPC_Flags(WPL_Code(n, s)) & WPLF_DISABLED);
}

string WPL_TypeName(float t)
{
	if (t == WPL_JUMP)        return "jump";
	if (t == WPL_CROUCHJUMP)  return "cjump";
	if (t == WPL_DROP)        return "drop";
	if (t == WPL_CROUCH)      return "crouch";
	if (t == WPL_LADDER_UP)   return "ladderup";
	if (t == WPL_LADDER_DOWN) return "ladderdown";
	if (t == WPL_DOOR)        return "door";
	if (t == WPL_TELEPORT)    return "tele";
	if (t == WPL_SWIM)        return "swim";
	return "walk";
}

float WPL_TypeFromName(string s)
{
	for (float t = 0; t < WPL_TYPES; t = t + 1)
		if (WPL_TypeName(t) == s) return t;
	if (s == "ladder") return WPL_LADDER_UP;
	return -1;
}

// Path cost of one link. Specials cost more than their length so a bot only
// jumps or climbs when walking round is genuinely longer.
float WP_TypeCost(float type, float dist)
{
	if (type == WPL_JUMP)        return dist + 48;
	if (type == WPL_CROUCHJUMP)  return dist + 72;
	if (type == WPL_DROP)        return dist + 24;
	if (type == WPL_CROUCH)      return dist * 1.6;
	if (type == WPL_LADDER_UP)   return dist * 1.5 + 64;
	if (type == WPL_LADDER_DOWN) return dist * 1.5 + 64;
	if (type == WPL_DOOR)        return dist + 96;
	if (type == WPL_TELEPORT)    return 64;
	if (type == WPL_SWIM)        return dist * 1.8;
	return dist;
}

float WP_CellKey(float cx, float cy)
{
	float k = cx * 131 + cy * 977 + 600000;
	return k - floor(k / WP_GRID) * WP_GRID;
}

void WP_GridInsert(entity n)
{
	float k = WP_CellKey(floor(n.origin_x / WP_CELL), floor(n.origin_y / WP_CELL));
	n.wp_gridNext = wp_grid[k];
	wp_grid[k] = n;
}

void WP_GridRebuild()
{
	for (float k = 0; k < WP_GRID; k = k + 1)
		wp_grid[k] = world;
	for (entity n = wp_first; n; n = n.wp_allNext)
		if (!(n.wp_flags & WPN_DEAD)) WP_GridInsert(n);
}

void WP_Clear()
{
	entity n = wp_first;
	while (n)
	{
		entity nx = n.wp_allNext;
		remove(n);
		n = nx;
	}
	wp_first = world;
	wp_count = 0;
	wp_linkCount = 0;
	for (float k = 0; k < WP_GRID; k = k + 1)
		wp_grid[k] = world;
	wp_dirty = FALSE;
}

entity WP_AddNode(vector o, float flags)
{
	if (wp_count >= WP_MAX) return world;

	entity n = spawn();
	n.classname = "wp_node";
	n.wp_isNode = TRUE;
	n.wp_flags  = flags;
	n.solid     = SOLID_NOT;
	n.movetype  = MOVETYPE_NONE;
	n.origin    = o;          // deliberately not setorigin: never linked into the world

	n.wp_allNext = wp_first;
	wp_first = n;
	wp_count = wp_count + 1;
	WP_GridInsert(n);
	wp_dirty = TRUE;
	return n;
}

float WP_FindSlot(entity a, entity b)
{
	for (float s = 0; s < WP_LINKS; s = s + 1)
		if (WPL_Dest(a, s) == b) return s;
	return -1;
}

// Returns the link id, or -1 when the node has no room and nothing was worth
// evicting.
float WP_AddLink(entity a, entity b, float type, float flags, float ent)
{
	if (a == b) return -1;
	if (!WP_Live(a) || !WP_Live(b)) return -1;

	float s = WP_FindSlot(a, b);
	if (s >= 0)
	{
		// An edit always wins. Otherwise the existing link stands, except that a
		// fresh observation re-enables one that failures switched off.
		float old = WPC_Flags(WPL_Code(a, s));
		float edit = (flags & WPLF_EDITED);
		if (edit || ((old & WPLF_DISABLED) && !(old & WPLF_EDITED)))
		{
			WPL_SetCodeRaw(a, s, WPC_Make(type, flags, ent));
			WPL_SetFail(a, s, 0);
			wp_dirty = TRUE;
		}
		return WPL_Id(a, s);
	}

	for (s = 0; s < WP_LINKS; s = s + 1)
		if (!WP_Live(WPL_Dest(a, s))) break;

	if (s >= WP_LINKS)
	{
		// Full. Evict a disabled link first, then, only for an edit or an
		// observation, the most failed generated walk link.
		float victim = -1;
		float worst = -1;
		for (float i = 0; i < WP_LINKS; i = i + 1)
		{
			float c = WPL_Code(a, i);
			if (WPC_Flags(c) & WPLF_EDITED) continue;
			if (WPC_Flags(c) & WPLF_DISABLED) { victim = i; break; }
			if (!(flags & (WPLF_EDITED | WPLF_LEARNED))) continue;
			if (WPC_Type(c) != WPL_WALK) continue;
			if (WPL_Fail(a, i) > worst) { worst = WPL_Fail(a, i); victim = i; }
		}
		if (victim < 0) return -1;
		s = victim;
	}
	else
	{
		wp_linkCount = wp_linkCount + 1;
	}

	WPL_SetDest(a, s, b);
	WPL_SetCodeRaw(a, s, WPC_Make(type, flags, ent));
	WPL_SetFail(a, s, 0);
	wp_dirty = TRUE;
	return WPL_Id(a, s);
}

void WP_RemoveLink(entity a, float s)
{
	if (!WPL_Dest(a, s)) return;
	WPL_SetDest(a, s, world);
	WPL_SetCodeRaw(a, s, 0);
	WPL_SetFail(a, s, 0);
	wp_linkCount = wp_linkCount - 1;
	wp_dirty = TRUE;
}

void WP_DisableLinkId(float id)
{
	entity a = WPL_IdNode(id);
	float s = WPL_IdSlot(id);
	if (!WP_Live(a)) return;
	float c = WPL_Code(a, s);
	WPL_SetCodeRaw(a, s, WPC_Make(WPC_Type(c), WPC_Flags(c) | WPLF_DISABLED, WPC_Ent(c)));
	wp_dirty = TRUE;
}

// A traversal went wrong. Enough of them, from any bot, and the link is switched
// off for good, which is how a bad generated link heals itself.
void WP_LinkFailed(float id)
{
	if (id < 0) return;
	entity a = WPL_IdNode(id);
	float s = WPL_IdSlot(id);
	if (!WP_Live(a)) return;
	float f = WPL_Fail(a, s) + 1;
	WPL_SetFail(a, s, f);
	if (f >= WPL_FAIL_DISABLE && !(WPC_Flags(WPL_Code(a, s)) & WPLF_EDITED))
		WP_DisableLinkId(id);
}

void WP_LinkSucceeded(float id)
{
	if (id < 0) return;
	entity a = WPL_IdNode(id);
	float s = WPL_IdSlot(id);
	if (!WP_Live(a)) return;
	float f = WPL_Fail(a, s);
	if (f > 0) WPL_SetFail(a, s, f - 1);
}

float WPL_IdType(float id)
{
	if (id < 0) return WPL_WALK;
	return WPC_Type(WPL_Code(WPL_IdNode(id), WPL_IdSlot(id)));
}

float WPL_IdEnt(float id)
{
	if (id < 0) return 0;
	return WPC_Ent(WPL_Code(WPL_IdNode(id), WPL_IdSlot(id)));
}

void WP_KillNode(entity n)
{
	if (!WP_Live(n)) return;
	n.wp_flags = n.wp_flags | WPN_DEAD;
	for (float s = 0; s < WP_LINKS; s = s + 1)
		WP_RemoveLink(n, s);
	WP_GridRebuild();
	wp_dirty = TRUE;
}

// Nearest live node to p within `radius`, flat distance, height difference no
// more than maxdz. No trace: this is the cheap query everything else builds on.
entity WP_NearestRaw(vector p, float radius, float maxdz)
{
	entity best = world;
	float bestD = radius;
	float r = ceil(radius / WP_CELL);
	float cx = floor(p_x / WP_CELL);
	float cy = floor(p_y / WP_CELL);

	for (float ix = cx - r; ix <= cx + r; ix = ix + 1)
	for (float iy = cy - r; iy <= cy + r; iy = iy + 1)
	{
		for (entity n = wp_grid[WP_CellKey(ix, iy)]; n; n = n.wp_gridNext)
		{
			if (fabs(n.origin_z - p_z) > maxdz) continue;
			float dx = n.origin_x - p_x;
			float dy = n.origin_y - p_y;
			float d = sqrt(dx * dx + dy * dy);
			if (d < bestD) { bestD = d; best = n; }
		}
	}
	return best;
}

// Nearest node that can actually be walked to from p: the four closest in range
// are tried in order with a line trace, since the closest node is often the one
// on the other side of a wall.
entity WP_Nearest(vector p, entity ignore)
{
	entity c0 = world, c1 = world, c2 = world, c3 = world;
	float d0 = 99999, d1 = 99999, d2 = 99999, d3 = 99999;
	float cx = floor(p_x / WP_CELL);
	float cy = floor(p_y / WP_CELL);

	for (float ix = cx - 2; ix <= cx + 2; ix = ix + 1)
	for (float iy = cy - 2; iy <= cy + 2; iy = iy + 1)
	{
		for (entity n = wp_grid[WP_CellKey(ix, iy)]; n; n = n.wp_gridNext)
		{
			if (fabs(n.origin_z - p_z) > 96) continue;
			float d = vlen(n.origin - p);
			if (d > 384) continue;
			if (d < d0)      { c3 = c2; d3 = d2; c2 = c1; d2 = d1; c1 = c0; d1 = d0; c0 = n; d0 = d; }
			else if (d < d1) { c3 = c2; d3 = d2; c2 = c1; d2 = d1; c1 = n; d1 = d; }
			else if (d < d2) { c3 = c2; d3 = d2; c2 = n; d2 = d; }
			else if (d < d3) { c3 = n; d3 = d; }
		}
	}

	vector lift = '0 0 16';
	if (c0) { traceline(p + lift, c0.origin + lift, WP_NOMON, ignore); if (trace_fraction == 1) return c0; }
	if (c1) { traceline(p + lift, c1.origin + lift, WP_NOMON, ignore); if (trace_fraction == 1) return c1; }
	if (c2) { traceline(p + lift, c2.origin + lift, WP_NOMON, ignore); if (trace_fraction == 1) return c2; }
	if (c3) { traceline(p + lift, c3.origin + lift, WP_NOMON, ignore); if (trace_fraction == 1) return c3; }

	if (c0 && d0 < 96) return c0;
	return world;
}

// Content that must never hold a node or be walked into.
float WP_BadContents(vector p)
{
	float c = pointcontents(p);
	return (c == CONTENT_LAVA || c == CONTENT_SLIME || c == CONTENT_SKY || c == CONTENT_SOLID);
}
