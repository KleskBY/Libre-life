// Path following on the bot waypoint graph (bot/wp_*.qc).
//
// A route lives on the bot's own fields, eight hops at a time (bot/wp_path.qc),
// so no query from another bot or a monster can overwrite it. A longer route
// repaths when its window runs out.
//
// At most WPA_PER_FRAME searches run per server frame. A bot refused one keeps
// walking the hops it has, or walks straight at the goal for that frame.
//
// A special link starts at a node: the jump was found walking from that node in
// one direction, so a bot that is off to the side walks onto the start node
// before it tries to take the link.

#define BOT_REPATH_GAP  1.5   // seconds before a failed route is retried

float Bot_NavReady()
{
	return WP_Ready();
}

void Bot_ClearPath(entity bot)
{
	bot.bot_pathLen   = 0;
	bot.bot_pathPos   = 0;
	bot.bot_pathTotal = 0;
	bot.bot_pathStart = world;
}

// A straight segment a player could walk: hull clear, roughly level, floor under
// the middle. Stairs fail the hull trace, which only means the graph is used.
float Bot_ClearWalk(entity bot, vector from, vector to)
{
	if (fabs(to_z - from_z) > 40) return FALSE;
	tracebox(from, PLAYER_STAND_SIZE_MIN, PLAYER_STAND_SIZE_MAX, to, WP_NOMON, bot);
	if (trace_fraction < 1) return FALSE;

	vector mid = (from + to) * 0.5;
	tracebox(mid + '0 0 8', PLAYER_STAND_SIZE_MIN, PLAYER_STAND_SIZE_MAX, mid - '0 0 48', WP_NOMON, bot);
	return trace_fraction < 1;
}

float Bot_RequestPath(entity bot, vector dest)
{
	if (!WP_Ready()) return FALSE;
	if (time < bot.bot_repathAt) return FALSE;
	if (!WP_PathBudget()) return FALSE;

	bot.bot_pathGoal = dest;
	entity from = WP_Nearest(bot.origin, bot);
	entity to   = WP_Nearest(dest, world);
	if (!from || !to)
	{
		bot.bot_repathAt = time + BOT_REPATH_GAP;
		Bot_ClearPath(bot);
		return FALSE;
	}

	if (from == to)
	{
		bot.bot_h0 = to;
		bot.bot_l0 = 0;
		bot.bot_pathTotal = 1;
		bot.bot_pathLen   = 1;
		bot.bot_pathPos   = 0;
		bot.bot_pathStart = from;
		Bot_BeginLink(bot);
		return TRUE;
	}

	// A flanking bot prices every node the enemy can see, so the route goes round.
	entity tgt = bot.bot_target;
	if (time < bot.bot_flankUntil && tgt)
		WP_SetThreat(TRUE, tgt.origin + tgt.view_ofs);

	float total = WP_FindPath(bot, from, to);
	WP_SetThreat(FALSE, '0 0 0');

	if (total <= 0)
	{
		bot.bot_repathAt = time + BOT_REPATH_GAP;
		Bot_ClearPath(bot);
		return FALSE;
	}

	bot.bot_pathTotal = total;
	bot.bot_pathLen   = (total < WP_HOPS) ? total : WP_HOPS;
	bot.bot_pathPos   = 0;
	bot.bot_pathStart = from;
	Bot_BeginLink(bot);
	return TRUE;
}

// Walk toward `dest` along the graph. FALSE means no route this frame and the
// caller should walk straight at it.
float Bot_FollowPath(entity bot, vector dest, float wish)
{
	if (!WP_Ready()) return FALSE;

	if (Bot_FlatDist(bot.origin, dest) < 140)
		if (Bot_ClearWalk(bot, bot.origin, dest))
		{
			Bot_ClearPath(bot);
			Bot_MoveTo(bot, dest, wish);
			return TRUE;
		}

	float need = (bot.bot_pathLen <= 0);
	if (!need && vlen(dest - bot.bot_pathGoal) > 96) need = TRUE;
	if (need)
		if (!Bot_RequestPath(bot, dest)) return FALSE;
	if (bot.bot_pathLen <= 0) return FALSE;

	entity hop = WP_HopNode(bot, bot.bot_pathPos);
	if (!WP_Live(hop))
	{
		Bot_ClearPath(bot);
		return FALSE;
	}
	float type = Bot_LinkType(bot);

	// Onto the start of a special link first.
	entity src = (bot.bot_pathPos == 0) ? bot.bot_pathStart : WP_HopNode(bot, bot.bot_pathPos - 1);
	if (Bot_IsSpecial(type) && src && !bot.bot_jumped && (bot.flags & FL_ONGROUND))
	{
		float offStart = Bot_FlatDist(bot.origin, src.origin);
		if (offStart > 56 && Bot_FlatDist(bot.origin, hop.origin) > Bot_FlatDist(src.origin, hop.origin) - 16)
		{
			Bot_MoveTo(bot, src.origin, wish);
			return TRUE;
		}
	}

	if (Bot_HopReached(bot, hop, type))
	{
		float k = WP_HopLink(bot, bot.bot_pathPos);
		if (k) WP_LinkSucceeded(k - 1);
		bot.bot_lastGood = hop;
		bot.bot_pathPos = bot.bot_pathPos + 1;

		if (bot.bot_pathPos >= bot.bot_pathLen)
		{
			float more = bot.bot_pathTotal > bot.bot_pathLen;
			Bot_ClearPath(bot);
			// A route longer than the window repaths from here next frame.
			Bot_MoveTo(bot, more ? hop.origin : dest, wish);
			return TRUE;
		}

		hop  = WP_HopNode(bot, bot.bot_pathPos);
		type = Bot_LinkType(bot);
		Bot_BeginLink(bot);
	}

	// Cut corners over walk links that have a clear line.
	if (type == WPL_WALK && time > bot.bot_pullAt)
	{
		bot.bot_pullAt = time + 0.25;
		float next = bot.bot_pathPos + 1;
		if (next < bot.bot_pathLen)
		{
			float nk = WP_HopLink(bot, next);
			entity nh = WP_HopNode(bot, next);
			if (nk && WP_Live(nh))
				if (WPL_IdType(nk - 1) == WPL_WALK && Bot_ClearWalk(bot, bot.origin, nh.origin))
				{
					bot.bot_pathPos = next;
					hop = nh;
					Bot_BeginLink(bot);
				}
		}
	}

	// A link that takes far longer than it should is a broken link.
	if (time - bot.bot_linkStart > bot.bot_linkBudget)
	{
		float fk = WP_HopLink(bot, bot.bot_pathPos);
		if (fk)
		{
			WP_Blacklist(bot, fk - 1, 20);
			WP_LinkFailed(fk - 1);
		}
		bot.bot_stuckEvents = bot.bot_stuckEvents + 1;
		Bot_ClearPath(bot);
		return FALSE;
	}

	Bot_Traverse(bot, hop, wish);
	return TRUE;
}

// Somewhere open to wander to when there is no graph yet.
vector Bot_ExploreGoal(entity bot)
{
	makevectors([0, random(0, 360), 0]);
	traceline(bot.origin, bot.origin + v_forward * 700, WP_NOMON, bot);
	float reach = 700 * trace_fraction - 32;
	if (reach < 64) reach = 64;
	return bot.origin + v_forward * reach;
}

// A node worth wandering to: far enough away to be a journey, biased toward the
// fighting when there is any and toward a team mate when there is one.
vector Bot_PickRoamGoal(entity bot)
{
	if (!WP_Ready()) return Bot_ExploreGoal(bot);

	vector best = bot.origin;
	float bestScore = -1;

	for (float i = 0; i < 16; i = i + 1)
	{
		entity n = wp_grid[floor(random() * WP_GRID)];
		if (!n) continue;
		if (random() < 0.5 && n.wp_gridNext) n = n.wp_gridNext;
		if (n.wp_flags & (WPN_DEAD | WPN_ORPHAN)) continue;

		float d = vlen(n.origin - bot.origin);
		if (d < 300) continue;

		float score = d * random(0.6, 1);
		if (bot.bot_lkp != '0 0 0')
			score = score + (2048 - vlen(n.origin - bot.bot_lkp)) * bot.bot_aggro;
		if (bot.bot_anchor)
			score = score + (1500 - vlen(n.origin - bot.bot_anchor.origin)) * 0.5;

		if (score > bestScore) { bestScore = score; best = n.origin; }
	}

	if (bestScore < 0) return Bot_ExploreGoal(bot);
	return best;
}
