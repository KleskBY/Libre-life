// Keeping a bot moving: the ledge guard, local avoidance, and stuck escalation.
//
// Stuck is measured as PROGRESS toward the current target, not as raw movement.
// A bot sliding along a wall moves plenty and gets nowhere; a bot waiting at a
// door moves nothing and is fine, because it has no wish. The target is kept by
// Bot_MoveTo, so every movement source feeds this, straight line fallbacks
// included.
//
// Escalation, each stage once per stall:
//
//   0.35s  probe ahead: crouch under a low ceiling, otherwise jump
//   0.8s   back off diagonally for a moment
//   1.5s   blacklist the link for this bot and count a failure against it; repath
//   4s     give up on the goal
//   10s    head back to the last node reached cleanly

// Refuse to walk off something the current link did not ask for. Lava, slime and
// trigger_hurt count as a ledge.
float Bot_LedgeGuard(entity bot, float allowDrop)
{
	if (allowDrop) return FALSE;
	if (!(bot.flags & FL_ONGROUND)) return FALSE;
	if (bot.bot_wishSpeed <= 0) return FALSE;

	vector ahead = bot.origin + bot.bot_wish * 28;
	tracebox(ahead, PLAYER_STAND_SIZE_MIN, PLAYER_STAND_SIZE_MAX, ahead - '0 0 64', WP_NOMON, bot);
	if (trace_startsolid) return FALSE;     // a wall, not a drop

	float danger = (trace_fraction == 1);
	if (!danger)
		if (WP_BadContents(trace_endpos + [0, 0, PLAYER_STAND_SIZE_MIN_z + 2])) danger = TRUE;
	if (!danger) return FALSE;

	Bot_StopMoving(bot);
	return TRUE;
}

// Slide round another player in the way. Between two bots the one with the lower
// seed steps aside, so a pair meeting in a corridor does not dance.
void Bot_Avoid(entity bot)
{
	if (bot.bot_wishSpeed <= 0) return;

	if (time < bot.bot_yieldUntil)
	{
		bot.bot_wish = bot.bot_yieldDir;
		return;
	}

	// findradius walks only entities linked into the world, so the thousands of
	// unlinked waypoint nodes cost nothing here, unlike a full chain scan.
	for (entity c = findradius(bot.origin, 72); c; c = c.chain)
	{
		if (c == bot) continue;
		if (c.classname != "player") continue;
		if (!IsAlive(c)) continue;

		vector d = c.origin - bot.origin;
		if (fabs(d_z) > 60) continue;
		d_z = 0;
		float dist = vlen(d);
		if (dist > 64 || dist < 1) continue;

		vector nd = d * (1 / dist);
		if (nd * bot.bot_wish < 0.5) continue;

		makevectors([0, vectoyaw(bot.bot_wish), 0]);
		vector aside = v_right;
		if (c.bot_isBot && bot.bot_seed > c.bot_seed) aside = aside * -1;

		if (dist < 40 && c.bot_isBot && bot.bot_seed < c.bot_seed)
		{
			bot.bot_yieldDir   = normalize(aside - nd * 0.5);
			bot.bot_yieldUntil = time + 0.5;
			bot.bot_wish       = bot.bot_yieldDir;
			return;
		}

		bot.bot_wish = normalize(bot.bot_wish + aside * (1.2 - dist / 64));
		return;
	}
}

// TRUE when the current route should be dropped and replanned.
float Bot_Unstuck(entity bot, float onLink)
{
	if (bot.bot_wishSpeed <= 0)
	{
		bot.bot_progAt = time;
		bot.bot_stuckStage = 0;
		return FALSE;
	}

	if (time < bot.bot_backUntil)
	{
		bot.bot_wish = bot.bot_backDir;
		bot.bot_wishSpeed = 0.9;
		return FALSE;
	}

	vector target = bot.bot_progTarget;
	float d = Bot_FlatDist(bot.origin, target) + fabs(target_z - bot.origin_z) * 0.5;
	if (d < bot.bot_progBest - 12)
	{
		bot.bot_progBest = d;
		bot.bot_progAt = time;
		bot.bot_stuckStage = 0;
		return FALSE;
	}

	float stuck = time - bot.bot_progAt;
	if (stuck > bot.bot_stuckWorst) bot.bot_stuckWorst = stuck;

	if (stuck > 0.35 && bot.bot_stuckStage < 1)
	{
		bot.bot_stuckStage = 1;
		float p = Bot_Probe(bot, bot.bot_wish);
		if (p == BOT_PROBE_HEAD) bot.bot_crouchUntil = time + 0.9;
		else                    Bot_Jump(bot, p != BOT_PROBE_STEP);
		return FALSE;
	}

	if (stuck > 0.8 && bot.bot_stuckStage < 2)
	{
		bot.bot_stuckStage = 2;
		makevectors([0, vectoyaw(bot.bot_wish), 0]);
		float side = (random() < 0.5) ? -1 : 1;
		bot.bot_backDir   = normalize(v_forward * -1 + v_right * side * 0.8);
		bot.bot_backUntil = time + 0.35;
		return FALSE;
	}

	if (stuck > 1.5 && bot.bot_stuckStage < 3)
	{
		bot.bot_stuckStage = 3;
		bot.bot_stuckEvents = bot.bot_stuckEvents + 1;
		if (onLink)
		{
			float k = WP_HopLink(bot, bot.bot_pathPos);
			if (k)
			{
				WP_Blacklist(bot, k - 1, 20);
				WP_LinkFailed(k - 1);
			}
		}
		return TRUE;
	}

	if (stuck > 4 && bot.bot_stuckStage < 4)
	{
		bot.bot_stuckStage = 4;
		bot.bot_goal = '0 0 0';
		return TRUE;
	}

	if (stuck > 10)
	{
		bot.bot_stuckStage = 0;
		bot.bot_progAt = time;
		bot.bot_progBest = 99999;
		if (bot.bot_lastGood) bot.bot_goal = bot.bot_lastGood.origin;
		return TRUE;
	}
	return FALSE;
}
