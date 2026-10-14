// Waypoint lifecycle: load or generate once per level, save what learning and the
// editor change, and draw the editor view.
//
// Multiplayer only. A singleplayer save writes every edict, and a few thousand
// node entities have no business in one; bots never run in singleplayer anyway.
//
// The manager is created lazily from the first player frame rather than from
// worldspawn, so the core node graph it imports from has been built and every
// map entity it seeds from has spawned.

float  wpm_loaded;
float  wpm_needGen;
entity wpm_ent;
float  wpm_saveAt;
float  wpm_drawAt;

float Bot_Count();   // bot/client.qc

float WP_Enabled()
{
	return IsMultiplayer();
}

// Regenerate on request, keeping hand edits. Runs in the background.
void WP_RequestGenerate()
{
	wpm_loaded = TRUE;
	wpm_needGen = FALSE;
	WPG_Start(TRUE);
}

float WP_NodeColour(entity n)
{
	if (n.wp_flags & WPN_EDITED) return 111;
	if (n.wp_flags & WPN_ORPHAN) return 79;
	if (n.wp_flags & WPN_HUMAN)  return 144;
	if (n.wp_flags & WPN_ISLAND) return 208;
	return 254;
}

void WP_DrawLink(vector a, vector b, float t)
{
	if (t == WPL_WALK)                           te_beam(world, a, b);
	else if (t == WPL_JUMP || t == WPL_CROUCHJUMP) te_lightning1(world, a, b);
	else if (t == WPL_DROP)                      te_lightning2(world, a, b);
	else                                         te_lightning3(world, a, b);
}

// Nodes and links around one viewer. Walk links only nearby, specials further
// out, and a hard cap, because every beam is a temp entity sent to everyone.
void WP_DrawFor(entity v)
{
	float beams = 0;
	float cx = floor(v.origin_x / WP_CELL);
	float cy = floor(v.origin_y / WP_CELL);

	for (float ix = cx - 7; ix <= cx + 7; ix = ix + 1)
	for (float iy = cy - 7; iy <= cy + 7; iy = iy + 1)
	{
		for (entity n = wp_grid[WP_CellKey(ix, iy)]; n; n = n.wp_gridNext)
		{
			if (fabs(n.origin_z - v.origin_z) > 320) continue;
			float d = vlen(n.origin - v.origin);
			if (d > 900) continue;

			particle(n.origin - '0 0 16', '0 0 0', WP_NodeColour(n), 8);

			for (float s = 0; s < WP_LINKS; s = s + 1)
			{
				entity to = WPL_Dest(n, s);
				if (!WP_Live(to)) continue;
				float c = WPL_Code(n, s);
				if (WPC_Flags(c) & WPLF_DISABLED) continue;
				float t = WPC_Type(c);

				if (t == WPL_WALK)
				{
					if (d > 400) continue;
					// Each two way walk link once.
					if (WP_FindSlot(to, n) >= 0 && num_for_edict(to) < num_for_edict(n)) continue;
				}

				if (beams >= 96) return;
				beams = beams + 1;
				WP_DrawLink(n.origin - '0 0 16', to.origin - '0 0 12', t);
			}
		}
	}
}

void WP_ManagerThink()
{
	self.nextthink = time + 0.05;
	if (time < 2) return;

	if (!wpm_loaded)
	{
		wpm_loaded = TRUE;
		if (!WP_Load()) wpm_needGen = TRUE;
	}

	if (wpm_needGen && !WPG_Active())
	{
		if (Bot_Count() > 0 || cvar("bot_wp_autogen") >= 2)
		{
			wpm_needGen = FALSE;
			WPG_Start(TRUE);
		}
	}

	WPG_Step();

	if (wp_dirty && !WPG_Active() && time > wpm_saveAt && cvar("bot_wp_save"))
	{
		wpm_saveAt = time + 120;
		WP_Save();
	}

	if (time > wpm_drawAt)
	{
		wpm_drawAt = time + 0.2;
		for (entity c = findchainflags(flags, FL_CLIENT); c; c = c.chain)
			if (c.bot_wpShow) WP_DrawFor(c);
	}
}

void WP_EnsureManager()
{
	if (wpm_ent) return;
	if (!WP_Enabled()) return;

	wpm_ent = spawn();
	wpm_ent.classname = "wp_manager";
	wpm_ent.think = WP_ManagerThink;
	wpm_ent.nextthink = time + 0.1;
}
