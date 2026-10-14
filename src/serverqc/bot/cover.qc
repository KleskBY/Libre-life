// Cover and peek positions on the waypoint graph.
//
// A cover node is one the threat's eye cannot see. A good one also has a
// neighbour it CAN see, the peek node: step out, fire, step back. Candidates are
// scanned in rings outward from the bot so the nearest cover is found first, and
// the number of traces per search is capped, then cached for a moment, because
// this runs on the planner cadence for every bot under fire.

#define BOT_COVER_RINGS    5       // grid cells out from the bot, 640 units
#define BOT_COVER_TRACES   28
#define BOT_COVER_CACHE    1.2

float BotCover_Seen(vector eye, entity n, entity ignore)
{
	traceline(eye, n.origin + '0 0 20', WP_NOMON, ignore);
	return trace_fraction == 1;
}

entity Bot_FindCover(entity bot, entity threat)
{
	if (!WP_Ready() || !threat) return world;
	if (time < bot.bot_coverAt && WP_Live(bot.bot_coverNode)) return bot.bot_coverNode;
	bot.bot_coverAt = time + BOT_COVER_CACHE;

	vector eye = threat.origin + threat.view_ofs;
	entity best = world;
	entity bestPeek = world;
	float bestScore = -99999;
	float traces = 0;
	float cx = floor(bot.origin_x / WP_CELL);
	float cy = floor(bot.origin_y / WP_CELL);

	for (float ring = 0; ring <= BOT_COVER_RINGS; ring = ring + 1)
	{
		for (float ix = cx - ring; ix <= cx + ring; ix = ix + 1)
		for (float iy = cy - ring; iy <= cy + ring; iy = iy + 1)
		{
			if (fabs(ix - cx) != ring && fabs(iy - cy) != ring) continue;

			for (entity n = wp_grid[WP_CellKey(ix, iy)]; n; n = n.wp_gridNext)
			{
				if (traces >= BOT_COVER_TRACES) break;
				if (n.wp_flags & (WPN_DEAD | WPN_ORPHAN)) continue;
				if (fabs(n.origin_z - bot.origin_z) > 160) continue;

				float d = vlen(n.origin - bot.origin);
				float td = vlen(n.origin - threat.origin);
				if (td < 220) continue;

				traces = traces + 1;
				if (BotCover_Seen(eye, n, threat)) continue;

				float score = 800 - d;
				if (td > 1400) score = score - (td - 1400);

				entity peek = world;
				for (float s = 0; s < WP_LINKS; s = s + 1)
				{
					if (traces >= BOT_COVER_TRACES) break;
					if (!WPL_Usable(n, s)) continue;
					if (WPC_Type(WPL_Code(n, s)) != WPL_WALK) continue;
					entity m = WPL_Dest(n, s);
					traces = traces + 1;
					if (BotCover_Seen(eye, m, threat)) { peek = m; break; }
				}
				if (peek) score = score + 400;

				if (score > bestScore)
				{
					bestScore = score;
					best = n;
					bestPeek = peek;
				}
			}
		}
		// The nearest ring with a peek pair is good enough.
		if (bestPeek) break;
	}

	bot.bot_coverNode = best;
	bot.bot_peekNode  = bestPeek;
	return best;
}

// Where to go to break line of sight. Without cover, simply away.
vector Bot_PickCover(entity bot, entity threat)
{
	if (!threat) return bot.origin;
	entity n = Bot_FindCover(bot, threat);
	if (n) return n.origin;
	return bot.origin + normalize(bot.origin - threat.origin) * 300;
}
