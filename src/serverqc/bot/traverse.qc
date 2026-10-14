// Executing one waypoint link: how a bot actually takes a jump, a drop, a
// ladder or a teleporter.
//
// A bot client gets no usercmd from the engine, so nothing here presses a key
// and waits for physics to answer. Every special traversal is driven through
// .velocity, the same backend ordinary walking already uses.
//
// Ladders are climbed from QC on purpose: core Ladder_Touch returns for bots, so
// a bot touching one gets nothing from it.
//
// Every link carries a time budget. Overrunning it is a failure the steering
// layer reports against the link, which is what lets a bad generated link
// disable itself.

float Bot_FlatDist(vector a, vector b)
{
	vector d = b - a;
	d_z = 0;
	return vlen(d);
}

// Type of the link that leads into the hop being walked to.
float Bot_LinkType(entity bot)
{
	float k = WP_HopLink(bot, bot.bot_pathPos);
	if (!k) return WPL_WALK;
	return WPL_IdType(k - 1);
}

entity Bot_LinkEnt(entity bot)
{
	float k = WP_HopLink(bot, bot.bot_pathPos);
	if (!k) return world;
	float en = WPL_IdEnt(k - 1);
	if (en <= 0) return world;
	return edict_num(en);
}

float Bot_IsSpecial(float type)
{
	return type != WPL_WALK && type != WPL_DOOR && type != WPL_CROUCH;
}

void Bot_BeginLink(entity bot)
{
	entity hop = WP_HopNode(bot, bot.bot_pathPos);
	float type = Bot_LinkType(bot);

	float budget = vlen(hop.origin - bot.origin) / 150 * 2 + 1.5;
	if (type == WPL_LADDER_UP || type == WPL_LADDER_DOWN) budget = budget + 4;
	if (type == WPL_DOOR)     budget = budget + 3;
	if (type == WPL_TELEPORT) budget = budget + 3;
	if (type == WPL_JUMP || type == WPL_CROUCHJUMP || type == WPL_DROP) budget = budget + 1.5;

	bot.bot_linkStart  = time;
	bot.bot_linkBudget = budget;
	bot.bot_jumped     = FALSE;
}

float Bot_InBox(entity bot, entity e, float pad)
{
	if (bot.absmin_x > e.absmax_x + pad) return FALSE;
	if (bot.absmax_x < e.absmin_x - pad) return FALSE;
	if (bot.absmin_y > e.absmax_y + pad) return FALSE;
	if (bot.absmax_y < e.absmin_y - pad) return FALSE;
	if (bot.absmin_z > e.absmax_z + pad) return FALSE;
	if (bot.absmax_z < e.absmin_z - pad) return FALSE;
	return TRUE;
}

float Bot_HopReached(entity bot, entity hop, float type)
{
	float flat = Bot_FlatDist(bot.origin, hop.origin);
	float dz = hop.origin_z - bot.origin_z;
	float grounded = (bot.flags & FL_ONGROUND) ? TRUE : FALSE;

	if (type == WPL_LADDER_UP)   return flat < 44 && dz < 24 && dz > -48;
	if (type == WPL_LADDER_DOWN) return flat < 48 && fabs(dz) < 32 && grounded;
	if (type == WPL_JUMP || type == WPL_CROUCHJUMP || type == WPL_DROP)
		return flat < 44 && fabs(dz) < 36 && grounded;
	if (type == WPL_TELEPORT)    return flat < 72 && fabs(dz) < 72;
	return flat < 36 && fabs(dz) < 48;
}

// Full air control toward a landing: a jump that drifts off its line is the
// commonest way to miss a ledge.
void Bot_AirSteer(entity bot, vector dir, float scale)
{
	float sp = Bot_WishSpeed(bot);
	if (sp < 200) sp = 200;
	bot.velocity_x = dir_x * sp * scale;
	bot.velocity_y = dir_y * sp * scale;
}

void Bot_TraverseLadder(entity bot, entity hop, float type, float wish)
{
	entity lad = Bot_LinkEnt(bot);
	if (!lad)
	{
		Bot_MoveTo(bot, hop.origin, wish);
		return;
	}

	vector lc = (lad.absmin + lad.absmax) * 0.5;
	vector toHop = hop.origin - bot.origin;
	toHop_z = 0;
	vector dir = (vlen(toHop) > 1) ? normalize(toHop) : '0 0 0';

	if (type == WPL_LADDER_UP && bot.origin_z >= lad.absmax_z - 4)
	{
		// Over the top: step off toward the exit node.
		Bot_MoveTo(bot, hop.origin, wish);
		if (!(bot.flags & FL_ONGROUND)) Bot_AirSteer(bot, dir, 1);
		return;
	}

	if (!Bot_InBox(bot, lad, 8))
	{
		Bot_MoveTo(bot, [lc_x, lc_y, bot.origin_z], wish);
		return;
	}

	vector into = lc - bot.origin;
	into_z = 0;
	if (vlen(into) > 1) into = normalize(into) * 60;

	if (type == WPL_LADDER_UP)
	{
		bot.velocity = [into_x, into_y, 200];
	}
	else
	{
		if (bot.origin_z <= hop.origin_z + 8)
		{
			Bot_MoveTo(bot, hop.origin, wish);
			return;
		}
		bot.velocity = [into_x, into_y, -180];
	}

	// Climbing is vertical: no wish, so the stuck detector does not read the
	// lack of horizontal progress as a bot going nowhere.
	bot.flags = bot.flags - (bot.flags & FL_ONGROUND);
	bot.bot_wish = dir;
	bot.bot_wishSpeed = 0;
}

// Drive one frame of the link into `hop`.
void Bot_Traverse(entity bot, entity hop, float wish)
{
	float type = Bot_LinkType(bot);
	vector to = hop.origin;
	vector flat = to - bot.origin;
	flat_z = 0;
	vector dir = (vlen(flat) > 1) ? normalize(flat) : '0 0 0';

	if (type == WPL_CROUCH) bot.bot_crouchUntil = time + 0.25;

	if (type == WPL_JUMP || type == WPL_CROUCHJUMP)
	{
		float crouch = (type == WPL_CROUCHJUMP);
		Bot_MoveTo(bot, to, 1);

		if (bot.flags & FL_ONGROUND)
		{
			if (!bot.bot_jumped || time - bot.bot_linkStart > 1)
			{
				float p = Bot_Probe(bot, dir);
				float rise = to_z - bot.origin_z;
				float close = vlen(flat) < 72;
				if (p == BOT_PROBE_STEP || p == BOT_PROBE_LEDGE || (close && rise > WPG_STEPUP))
					if (Bot_Jump(bot, crouch)) bot.bot_jumped = TRUE;
			}
		}
		else
		{
			Bot_AirSteer(bot, dir, 1);
			if (crouch) bot.bot_crouchUntil = time + 0.2;
		}
		return;
	}

	if (type == WPL_DROP)
	{
		Bot_MoveTo(bot, to, 0.8);
		if (!(bot.flags & FL_ONGROUND)) Bot_AirSteer(bot, dir, 0.8);
		return;
	}

	if (type == WPL_LADDER_UP || type == WPL_LADDER_DOWN)
	{
		Bot_TraverseLadder(bot, hop, type, wish);
		return;
	}

	if (type == WPL_TELEPORT)
	{
		entity tp = Bot_LinkEnt(bot);
		if (tp && Bot_FlatDist(bot.origin, to) > 72)
		{
			vector tc = (tp.absmin + tp.absmax) * 0.5;
			Bot_MoveTo(bot, [tc_x, tc_y, bot.origin_z], wish);
			return;
		}
	}

	Bot_MoveTo(bot, to, wish);
}
