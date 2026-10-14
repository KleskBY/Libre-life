// What a bot knows about, and how it finds out.
//
// Three filters in increasing cost: the potentially visible set, then the view
// cone, then a real trace. The trace is deliberately not IsVisible, which passes
// nomonsters TRUE and would happily see straight through anything solid that is
// an entity rather than world geometry.
//
// Hearing is free. bot_awareness.qc already writes .bot_noise and .bot_visibility
// on every player every frame, and until now nothing on the server read either.
// A sprinting player is loud, a crouched one in the dark is hard to pick out,
// and bots get both for the cost of a field read.

void Player_HitboxResolve();     // player/torso.qc

#define BOT_SIGHT      3000
#define BOT_FOV_DOT    -0.15   // roughly 190 degrees, generous like a player's
#define BOT_HEARSCALE  14      // units of through wall awareness per noise point
#define BOT_FORGET     6       // seconds a lost target stays worth hunting

float Bot_Hostile(entity bot, entity e)
{
	if (!e || e == bot) return FALSE;
	if (e.classname != "player") return FALSE;
	if (!IsAlive(e)) return FALSE;
	if (e.bot_down) return FALSE;
	if (e.flags & FL_NOTARGET) return FALSE;

	if (Bot_TeamsEnabled() && e.bot_team == bot.bot_team) return FALSE;

	// Nobody is hostile in the cooperative modes; the mutants are the enemy.
	float gm = cvar("gamemode");
	if (gm == MODE_COOP || gm == MODE_SURV) return FALSE;

	return TRUE;
}

// A monster worth shooting at. Survival is entirely this.
float Bot_HostileMonster(entity bot, entity e)
{
	if (!e || !(e.flags & FL_MONSTER)) return FALSE;
	return IsAlive(e);
}

float Bot_InCone(entity bot, vector point)
{
	makevectors([0, bot.v_angle_y, 0]);
	vector d = point - (bot.origin + bot.view_ofs);
	d_z = 0;
	if (d == '0 0 0') return TRUE;
	return (normalize(d) * v_forward) >= BOT_FOV_DOT;
}

// Line of sight, shaped like the grunt's rather than IsVisible's.
//
// Player_HitboxResolve is mandatory after any trace meant to find people: on the
// split body engines the torso is a player_hitbox proxy, so a chest height trace
// lands on the proxy and never on the player.
float Bot_CanSee(entity bot, entity tgt)
{
	if (!tgt) return FALSE;

	vector eye = bot.origin + bot.view_ofs;
	traceline(eye, tgt.origin + tgt.view_ofs, FALSE, bot);
	Player_HitboxResolve();
	if (trace_fraction == 1 || trace_ent == tgt) return TRUE;

	// Second try at the chest: a target crouched behind cover often has only its
	// upper body exposed, and eye to eye misses that.
	traceline(eye, tgt.origin + '0 0 8', FALSE, bot);
	Player_HitboxResolve();
	return (trace_fraction == 1 || trace_ent == tgt);
}

// Remembering a target is not seeing it. Aim and trigger both ask this, so a bot
// that lost sight looks where the target was last seen instead of tracking it
// through the wall, and never spends a magazine on plaster. Rechecked at most
// every 0.1s; the planner's 0.4s cadence is too coarse for a trigger.
float Bot_TargetVisible(entity bot, entity tgt)
{
	if (!tgt) return FALSE;
	if (time >= bot.bot_losAt)
	{
		bot.bot_losAt = time + 0.1;
		bot.bot_los = Bot_CanSee(bot, tgt);
		if (bot.bot_los) bot.bot_lkp = tgt.origin;
	}
	return bot.bot_los;
}

// How far this bot can pick the target out, scaled by how visible the target is
// making itself. A dark, still, crouched stalker has to be much closer.
float Bot_SightRange(entity bot, entity tgt)
{
	float vis = tgt.bot_visibility;
	if (vis < 0) vis = 0;
	if (vis > 100) vis = 100;

	float f = 0.35 + (vis * 0.0065);          // 0.35 at pitch dark, 1.0 at fully lit
	f = f * (0.7 + bot.bot_skill * 0.3);
	return BOT_SIGHT * f;
}

float Bot_Score(entity bot, entity e, float dist)
{
	float s = 8000 - dist;
	if (e == bot.bot_target) s = s + 900;        // hysteresis, do not dither
	if (e.classname == "player") s = s + 600;      // a stalker outranks a mutant
	if (e.health < 40) s = s + 400;
	return s;
}

// Noise reaches through walls. It never acquires a target: it turns the bot's
// attention toward a place, which is what makes them investigate rather than
// wallhack.
void Bot_Listen(entity bot)
{
	for (entity c = findchainflags(flags, FL_CLIENT); c; c = c.chain)
	{
		if (!Bot_Hostile(bot, c)) continue;
		if (c.bot_noise <= 0) continue;

		float d = vlen(c.origin - bot.origin);
		if (d > c.bot_noise * BOT_HEARSCALE) continue;

		bot.bot_lkp = c.origin;
		if (!bot.bot_lostTime) bot.bot_lostTime = time;
	}
}

entity Bot_FindEnemy(entity bot)
{
	entity best = world;
	float bestScore = -100000;
	vector eye = bot.origin + bot.view_ofs;

	for (entity e = findradius(bot.origin, BOT_SIGHT); e; e = e.chain)
	{
		float isPlayer = Bot_Hostile(bot, e);
		float isMon    = Bot_HostileMonster(bot, e);
		if (!isPlayer && !isMon) continue;

		float d = vlen(e.origin - bot.origin);
		if (isPlayer && d > Bot_SightRange(bot, e)) continue;

		if (!checkpvs(eye, e)) continue;
		if (!Bot_InCone(bot, e.origin + e.view_ofs)) continue;
		if (!Bot_CanSee(bot, e)) continue;

		float s = Bot_Score(bot, e, d);
		if (s > bestScore) { bestScore = s; best = e; }
	}
	return best;
}

// Runs on the planner cadence. Owns .bot_target, .bot_sawTime,
// .bot_lostTime and .bot_lkp; nothing else writes them.
void Bot_Sense(entity bot)
{
	entity had = bot.bot_target;

	// A target that died, left, or went down stops being one immediately.
	if (had && (wasfreed(had) || !IsAlive(had) || had.bot_down))
	{
		bot.bot_target = world;
		bot.bot_lostTime = 0;
		had = world;
	}

	entity found = Bot_FindEnemy(bot);

	if (found)
	{
		if (found != had)
		{
			// A new face resets the clock, which is what the reaction delay in
			// the aim model counts from.
			bot.bot_sawTime = time;
			bot.bot_aimNextErr = 0;
		}
		bot.bot_target   = found;
		bot.bot_lkp      = found.origin;
		bot.bot_lostTime = 0;
		return;
	}

	if (had)
	{
		// Held a target, cannot see it now. Remember where it was and go look.
		if (!bot.bot_lostTime) bot.bot_lostTime = time;
		if (time - bot.bot_lostTime > BOT_FORGET)
		{
			bot.bot_target = world;
			bot.bot_lostTime = 0;
			bot.bot_lkp = '0 0 0';
		}
		return;
	}

	Bot_Listen(bot);

	if (bot.bot_lostTime && time - bot.bot_lostTime > BOT_FORGET)
	{
		bot.bot_lostTime = 0;
		bot.bot_lkp = '0 0 0';
	}
}
