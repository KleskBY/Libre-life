// `cmd wp ...`: the in-game waypoint editor.
//
// Everything placed or linked here carries the edited flag, and nothing the
// generator, learning or failure counting does ever overwrites it. `wp gen`
// regenerates around the edits rather than over them.
//
//   wp show [0|1]                 draw nodes and links around you
//   wp stats                      counts by link type
//   wp near                       the nearest node and its links
//   wp add                        a node here, walk-linked to clear neighbours
//   wp del                        remove the nearest node
//   wp from                       mark where a link starts (a node here)
//   wp to <type> [both]           link from the mark to here
//   wp unlink | wp disable        from the mark to the nearest node
//   wp save | load | gen | clear

void WP_EditMsg(string s)
{
	sprint(self, strcat("wp: ", s, "\n"));
}

entity WP_EditPick(entity p)
{
	return WP_NearestRaw(p.origin, 96, 64);
}

entity WP_EditNodeHere(entity p)
{
	entity n = WP_NearestRaw(p.origin, 48, 40);
	if (n)
	{
		n.wp_flags = n.wp_flags | WPN_EDITED;
		return n;
	}
	vector at = p.origin;
	if (WPG_Place(p.origin + '0 0 8', 64)) at = wpg_placed;
	return WP_AddNode(at, WPN_EDITED);
}

float WP_EditEntFor(float type, entity a, entity b)
{
	vector mid = (a.origin + b.origin) * 0.5;

	if (type == WPL_LADDER_UP || type == WPL_LADDER_DOWN)
	{
		entity best = world;
		float bestD = 200;
		for (entity e = find(world, classname, "func_ladder"); e; e = find(e, classname, "func_ladder"))
		{
			float d = vlen((e.absmin + e.absmax) * 0.5 - mid);
			if (d < bestD) { bestD = d; best = e; }
		}
		return best ? num_for_edict(best) : 0;
	}

	if (type == WPL_TELEPORT)
	{
		for (entity t = find(world, classname, "trigger_teleport"); t; t = find(t, classname, "trigger_teleport"))
			if (Bot_InBox(a, t, 48)) return num_for_edict(t);
	}
	return 0;
}

void WP_EditStats()
{
	float n0 = 0, dead = 0, orphans = 0, human = 0, edited = 0;
	float c0 = 0, c1 = 0, c2 = 0, c3 = 0, c4 = 0, c5 = 0, c6 = 0, c7 = 0, c8 = 0, off = 0;

	for (entity n = wp_first; n; n = n.wp_allNext)
	{
		if (n.wp_flags & WPN_DEAD) { dead = dead + 1; continue; }
		n0 = n0 + 1;
		if (n.wp_flags & WPN_ORPHAN) orphans = orphans + 1;
		if (n.wp_flags & WPN_HUMAN)  human = human + 1;
		if (n.wp_flags & WPN_EDITED) edited = edited + 1;

		for (float s = 0; s < WP_LINKS; s = s + 1)
		{
			if (!WP_Live(WPL_Dest(n, s))) continue;
			float c = WPL_Code(n, s);
			if (WPC_Flags(c) & WPLF_DISABLED) { off = off + 1; continue; }
			float t = WPC_Type(c);
			if (t == WPL_WALK) c0 = c0 + 1;
			else if (t == WPL_JUMP) c1 = c1 + 1;
			else if (t == WPL_CROUCHJUMP) c2 = c2 + 1;
			else if (t == WPL_DROP) c3 = c3 + 1;
			else if (t == WPL_CROUCH) c4 = c4 + 1;
			else if (t == WPL_LADDER_UP || t == WPL_LADDER_DOWN) c5 = c5 + 1;
			else if (t == WPL_DOOR) c6 = c6 + 1;
			else if (t == WPL_TELEPORT) c7 = c7 + 1;
			else c8 = c8 + 1;
		}
	}

	WP_EditMsg(strcat(ftos(n0), " nodes (", ftos(orphans), " unreachable, ", ftos(human), " learned, ", ftos(edited), " edited)"));
	WP_EditMsg(strcat("walk ", ftos(c0), " jump ", ftos(c1), " cjump ", ftos(c2), " drop ", ftos(c3)));
	WP_EditMsg(strcat("crouch ", ftos(c4), " ladder ", ftos(c5), " door ", ftos(c6), " tele ", ftos(c7)));
	WP_EditMsg(strcat("other ", ftos(c8), " disabled ", ftos(off), WPG_Active() ? ", generating" : "", wp_dirty ? ", unsaved" : ""));
	WP_EditMsg(strcat("file ", WP_FileName()));
}

void WP_EditNear()
{
	entity n = WP_EditPick(self);
	if (!n) { WP_EditMsg("no node within 96"); return; }

	WP_EditMsg(strcat("node ", ftos(num_for_edict(n)), " flags ", ftos(n.wp_flags), " at ", vtos(n.origin)));
	for (float s = 0; s < WP_LINKS; s = s + 1)
	{
		entity d = WPL_Dest(n, s);
		if (!WP_Live(d)) continue;
		float c = WPL_Code(n, s);
		string line = strcat("  -> ", ftos(num_for_edict(d)), " ", WPL_TypeName(WPC_Type(c)));
		line = strcat(line, " ", ftos(rint(vlen(d.origin - n.origin))), "u fails ", ftos(WPL_Fail(n, s)));
		if (WPC_Flags(c) & WPLF_DISABLED) line = strcat(line, " DISABLED");
		if (WPC_Flags(c) & WPLF_EDITED)   line = strcat(line, " edited");
		if (WPC_Flags(c) & WPLF_LEARNED)  line = strcat(line, " learned");
		sprint(self, strcat(line, "\n"));
	}
}

void WP_Command()
{
	if (!WP_Enabled())
	{
		WP_EditMsg("waypoints run in multiplayer only");
		return;
	}
	WP_EnsureManager();

	string sub = argv(1);
	string arg = argv(2);

	if (sub == "show")
	{
		self.bot_wpShow = (arg != "") ? stof(arg) : !self.bot_wpShow;
		WP_EditMsg(self.bot_wpShow ? "drawing on" : "drawing off");
		return;
	}
	if (sub == "stats") { WP_EditStats(); return; }
	if (sub == "near")  { WP_EditNear(); return; }

	if (sub == "add")
	{
		entity n = WP_EditNodeHere(self);
		if (!n) { WP_EditMsg("node limit reached"); return; }
		float linked = 0;
		for (entity m = wp_first; m; m = m.wp_allNext)
		{
			if (m == n || !WP_Live(m)) continue;
			if (vlen(m.origin - n.origin) > 128) continue;
			if (!Bot_ClearWalk(self, n.origin, m.origin)) continue;
			WP_AddLink(n, m, WPL_WALK, WPLF_EDITED, 0);
			WP_AddLink(m, n, WPL_WALK, WPLF_EDITED, 0);
			linked = linked + 1;
		}
		WP_EditMsg(strcat("node ", ftos(num_for_edict(n)), " added, ", ftos(linked), " walk links"));
		return;
	}

	if (sub == "del")
	{
		entity k = WP_EditPick(self);
		if (!k) { WP_EditMsg("no node within 96"); return; }
		WP_KillNode(k);
		WP_EditMsg("node removed");
		return;
	}

	if (sub == "from")
	{
		self.bot_wpFrom = WP_EditNodeHere(self);
		WP_EditMsg(strcat("link start at node ", ftos(num_for_edict(self.bot_wpFrom))));
		return;
	}

	if (sub == "to")
	{
		entity a = self.bot_wpFrom;
		if (!WP_Live(a)) { WP_EditMsg("use wp from first"); return; }
		float type = WPL_TypeFromName(arg);
		if (type < 0) type = WPL_WALK;

		entity b = WP_EditNodeHere(self);
		if (!b || b == a) { WP_EditMsg("stand somewhere else to end the link"); return; }

		float ent = WP_EditEntFor(type, a, b);
		WP_AddLink(a, b, type, WPLF_EDITED, ent);

		if (argv(3) == "both")
		{
			float back = type;
			if (type == WPL_LADDER_UP)   back = WPL_LADDER_DOWN;
			if (type == WPL_LADDER_DOWN) back = WPL_LADDER_UP;
			if (type == WPL_JUMP || type == WPL_CROUCHJUMP) back = WPL_DROP;
			WP_AddLink(b, a, back, WPLF_EDITED, ent);
		}

		self.bot_wpFrom = b;
		WP_EditMsg(strcat(WPL_TypeName(type), " link added, the mark moves here"));
		return;
	}

	if (sub == "unlink" || sub == "disable")
	{
		entity ua = self.bot_wpFrom;
		entity ub = WP_EditPick(self);
		if (!WP_Live(ua) || !ub) { WP_EditMsg("need wp from, then stand at the other end"); return; }
		float us = WP_FindSlot(ua, ub);
		if (us < 0) { WP_EditMsg("no link between them"); return; }
		if (sub == "unlink") WP_RemoveLink(ua, us);
		else                 WP_DisableLinkId(WPL_Id(ua, us));
		WP_EditMsg(sub == "unlink" ? "link removed" : "link disabled");
		return;
	}

	if (sub == "save")  { WP_Save(); WP_EditMsg("saved"); return; }
	if (sub == "load")  { WP_EditMsg(WP_Load() ? "loaded" : "no valid file for this map"); return; }
	if (sub == "gen")   { WP_RequestGenerate(); WP_EditMsg("regenerating, edits are kept"); return; }
	if (sub == "clear") { WP_Clear(); WP_EditMsg("all waypoints removed"); return; }

	WP_EditMsg("show | stats | near | add | del | from | to <walk|jump|cjump|drop|crouch|ladder|door|tele> [both] | unlink | disable | save | load | gen | clear");
}
