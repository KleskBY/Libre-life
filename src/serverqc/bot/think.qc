// The bot state machine, split across two cadences.
//
// The brain entity runs at BOT_TICK and does the expensive thinking: finding
// enemies, choosing a goal, asking the graph for a path. Bot_PerFrame runs
// every frame off the player hook and does the parts that need frame resolution:
// the aim settle curve, steering, and the trigger.
//
// Buttons are cleared at the top of every frame and re-driven from scratch. They
// are plain fields with no release event, so a button left set once is held down
// forever, and the burst counter would drift away from the shots that actually
// left the barrel.

void Bot_BuyPhase(entity bot);          // bot/economy.qc
void Bot_LullBuy(entity bot);           // bot/economy.qc
entity Bot_FindCasualty(entity bot);    // bot/tactics.qc
float Bot_ReviveStep(entity bot, entity casualty);
void Bot_PickAnchor(entity bot);

void Bot_ClearButtons(entity bot)
{
	bot.button0 = FALSE;
	bot.button2 = FALSE;
	bot.button3 = FALSE;
	bot.button4 = FALSE;
	bot.button5 = FALSE;
	bot.buttonuse = FALSE;
	bot.button6 = FALSE;
	bot.impulse = 0;
}

vector Bot_GoalForState(entity bot)
{
	entity tgt = bot.bot_target;

	if (bot.bot_state == BSTATE_REVIVE)
	{
		entity c = Bot_FindCasualty(bot);
		if (c) return c.origin;
	}

	if ((bot.bot_state == BSTATE_COVER || bot.bot_state == BSTATE_HEAL) && tgt)
		return Bot_PickCover(bot, tgt);

	// Step out to the peek node, hold and shoot there for a moment, then back
	// into cover to wait for the next opening.
	if (bot.bot_state == BSTATE_PEEK && tgt && WP_Live(bot.bot_peekNode))
	{
		if (time > bot.bot_peekUntil)
		{
			bot.bot_state  = BSTATE_COVER;
			bot.bot_peekAt = time + random(1.5, 3);
			return Bot_PickCover(bot, tgt);
		}
		if (Bot_FlatDist(bot.origin, bot.bot_peekNode.origin) < 40)
		{
			bot.bot_hold = TRUE;
			return bot.origin;
		}
		return bot.bot_peekNode.origin;
	}

	// Flank and push both close on the target; flanking differs in the route,
	// which prices every node the target can see (bot/nav.qc).
	if ((bot.bot_state == BSTATE_FLANK || bot.bot_state == BSTATE_PUSH) && tgt)
		return (bot.bot_state == BSTATE_FLANK && bot.bot_lkp != '0 0 0') ? bot.bot_lkp : tgt.origin;

	if (bot.bot_state == BSTATE_REARM && bot.bot_pickup)
		return bot.bot_pickup.origin;

	// Nothing to shoot with and no stomach for a knife fight: put distance
	// between the two of you rather than feed a free kill.
	if (time < bot.bot_breakUntil && tgt)
	{
		vector flee = normalize(bot.origin - tgt.origin);
		return bot.origin + flee * 700;
	}

	if (bot.bot_state == BSTATE_COMBAT && tgt)
	{
		float dist = vlen(tgt.origin - bot.origin);
		float pref = Bot_PrefRange(bot, Weapon_IDFromBit(bot.weapon));

		// Too far to shoot well: close. Too close for the weapon: back off.
		if (dist > pref * 1.3) return tgt.origin;
		if (dist < pref * 0.45)
		{
			vector away = bot.origin - tgt.origin;
			away_z = 0;
			away = normalize(away);

			// Only with room behind. Backing into a wall makes no progress, the
			// stuck recovery answers with a hop, and the bot bounces in place in
			// front of its target instead of fighting.
			tracebox(bot.origin, PLAYER_STAND_SIZE_MIN, PLAYER_STAND_SIZE_MAX, bot.origin + away * 128, WP_NOMON, bot);
			if (trace_fraction > 0.75)
			{
				bot.bot_backoff = TRUE;
				return bot.origin + away * 300;
			}
			bot.bot_hold = TRUE;
			return bot.origin;
		}

		// In the pocket. Hold ground and sidestep rather than travel. This is a
		// flag rather than a goal of `bot.origin`, because the planner runs at
		// 2.5 Hz while the origin moves every frame, so comparing the two later
		// would practically never match.
		bot.bot_hold = TRUE;
		return bot.origin;
	}

	if (bot.bot_state == BSTATE_HUNT && bot.bot_lkp != '0 0 0')
	{
		// At the last sighting and nobody there: check the exits, the way the
		// target was heading first.
		if (vlen(bot.bot_lkp - bot.origin) < 96 && bot.bot_searchLeft > 0 && WP_Ready())
		{
			bot.bot_searchLeft = bot.bot_searchLeft - 1;
			entity at = WP_NearestRaw(bot.bot_lkp, 128, 64);
			entity pick = world;
			float bestDot = -2;
			if (at)
				for (float s = 0; s < WP_LINKS; s = s + 1)
				{
					if (!WPL_Usable(at, s)) continue;
					entity nb = WPL_Dest(at, s);
					vector dir = nb.origin - at.origin;
					dir_z = 0;
					float dot = normalize(dir) * bot.bot_lkpDir + random(-0.3, 0.3);
					if (dot > bestDot) { bestDot = dot; pick = nb; }
				}
			if (pick)
			{
				bot.bot_lkp = pick.origin + normalize(pick.origin - at.origin) * 96;
				return bot.bot_lkp;
			}
			bot.bot_searchLeft = 0;
		}
		return bot.bot_lkp;
	}

	// Roaming. Re-pick only when the old goal is reached or gone stale.
	if (bot.bot_goal == '0 0 0' || vlen(bot.bot_goal - bot.origin) < 180)
		return Bot_PickRoamGoal(bot);

	return bot.bot_goal;
}

// The slow half. Enemy search, state, goal, path request.
void Bot_Plan(entity bot)
{
	if (time < bot.bot_nextPlan) return;
	bot.bot_nextPlan = time + BOT_PLAN + bot.bot_seed * 0.1;

	Bot_Sense(bot);
	Bot_Decide(bot);
	Bot_PickAnchor(bot);
	Bot_LullBuy(bot);

	bot.bot_hold = FALSE;
	bot.bot_backoff = FALSE;
	vector g = Bot_GoalForState(bot);
	if (g != bot.bot_goal)
	{
		bot.bot_goal = g;
		Bot_ClearPath(bot);
	}
}

// Stuck recovery, avoidance, the ledge guard and the physical push, shared by
// every state so none of them can walk into a wall forever.
void Bot_SteerTail(entity bot)
{
	float onPath = (bot.bot_pathLen > 0);
	float type = onPath ? Bot_LinkType(bot) : WPL_WALK;
	float allowDrop = onPath && Bot_IsSpecial(type);

	// Holding and backing off are deliberate: a goal that moves with the bot is
	// not a bot getting nowhere.
	if (!bot.bot_hold && !bot.bot_backoff)
		if (Bot_Unstuck(bot, onPath)) Bot_ClearPath(bot);

	Bot_Avoid(bot);
	Bot_LedgeGuard(bot, allowDrop);
	Bot_Locomote(bot);
}

// The fast half. Runs every frame while the bot is alive.
void Bot_PerFrame(entity bot)
{
	Bot_ClearButtons(bot);

	// AN OBSERVER PASSES IsAlive. PutObserverInServer leaves health at 666 and
	// deadflag at DEAD_NO so the death logic cannot grab it, which means every
	// alive test in this file says yes to a bot that is an invisible spectator
	// with no weapon, waiting out a Survival wave. It must sit still.
	if (bot.classname != "player")
	{
		Bot_StopMoving(bot);
		return;
	}

	// A casualty is still IsAlive, so this hook keeps running for one. It must
	// not fight or steer from the floor; the brain handles that state.
	if (bot.bot_down)
	{
		Bot_StopMoving(bot);
		Bot_Aim(bot);
		return;
	}

	entity tgt = bot.bot_target;
	float dist = tgt ? vlen(tgt.origin - bot.origin) : 0;

	Bot_Aim(bot);

	// Reviving and rearming steer themselves, but still go through the shared
	// steering tail below.
	float busy = FALSE;
	if (bot.bot_state == BSTATE_REVIVE)
	{
		entity c = Bot_FindCasualty(bot);
		if (c && Bot_ReviveStep(bot, c)) busy = TRUE;
	}
	if (!busy && bot.bot_state == BSTATE_REARM)
		if (Bot_PickupStep(bot, bot.bot_pickup)) busy = TRUE;

	if (!busy)
	{
		if (tgt && bot.bot_hold)
		{
			Bot_Strafe(bot, normalize(tgt.origin - bot.origin), 96);
		}
		else if (!bot.bot_hold && bot.bot_goal != '0 0 0')
		{
			float wish = 1;
			if (bot.bot_state == BSTATE_ROAM) wish = 0.75;

			if (!Bot_FollowPath(bot, bot.bot_goal, wish))
				Bot_MoveTo(bot, bot.bot_goal, wish);
		}
		else
		{
			Bot_StopMoving(bot);
		}
	}

	// SPRINT ONLY WHILE TRAVELLING.
	//
	// Three interlocks make sprinting and shooting mutually exclusive by design:
	// Player_Stance refuses sprint while button0 is held, Player_UpdateStamina
	// clears .running while winded or while shouldering, and Weapon_Attack
	// refuses to fire at all in STATE_RUN. So the rule is simply not to sprint
	// once there is a shot to take. The old rule was `!tgt`, which meant a bot
	// never ran toward a distant enemy at all.
	float wid = Weapon_IDFromBit(bot.weapon);
	float far = vlen(bot.bot_goal - bot.origin) > 400;
	float shootable = tgt && Bot_InEffectiveRange(bot, wid, dist);

	bot.button4 = (bot.bot_wishSpeed > 0 && far && !shootable
	               && !bot.bot_stamBlocked);

	// Patch up once nothing is shooting. Player_Heal ignores a repeat while a
	// heal is already running, so asserting it every frame is harmless.
	if (bot.bot_state == BSTATE_HEAL && !tgt && bot.medkits > 0 && bot.health < 100)
		bot.impulse = BOT_IMPULSE_HEAL;

	Bot_SteerTail(bot);
	if (!busy) Bot_Fight(bot, tgt, dist);
}

void Bot_DownedFrame(entity bot)
{
	// The casualty is pinned by pausetime already. Keep looking at whatever put
	// it there and do not shoot.
	Bot_ClearButtons(bot);
	Bot_StopMoving(bot);
	Bot_Aim(bot);
}

// Death wipes the fight. Without this a respawned bot still holds its old target
// and walks, aims and shoots at where it last knew someone to be.
void Bot_ForgetCombat(entity bot)
{
	bot.bot_target     = world;
	bot.bot_lostTime   = 0;
	bot.bot_lkp        = '0 0 0';
	bot.bot_los        = FALSE;
	bot.bot_state      = BSTATE_ROAM;
	bot.bot_goal       = '0 0 0';
	bot.bot_hold       = FALSE;
	bot.bot_burstLeft  = 0;
	bot.bot_breakUntil = 0;
	bot.bot_flankUntil = 0;
	bot.bot_coverNode  = world;
	bot.bot_peekNode   = world;
	bot.bot_searchLeft = 0;
	bot.bot_backoff    = FALSE;
	bot.reload           = FALSE;    // death replaces the think that would have finished it
	bot.bot_reloadSince = 0;
	Bot_ClearPath(bot);
}

void Bot_DeadFrame(entity bot)
{
	Bot_ForgetCombat(bot);
	Bot_ClearButtons(bot);
	Bot_StopMoving(bot);

	// Spend the wait between lives at the trader. This is the reason the brain
	// is its own entity: the player hook does not run for a dead player.
	Bot_BuyPhase(bot);

	// Core's Player_DeathThink respawns a bot on its own, so nothing here has to
	// press a key.
}

// Called from the brain entity, with self already swapped to the bot.
void Bot_Frame(entity bot)
{
	// Observer first, for the reason in Bot_PerFrame: it reads as alive.
	if (bot.classname != "player") { Bot_DeadFrame(bot); return; }
	if (!IsAlive(bot))   { Bot_DeadFrame(bot);   return; }
	if (bot.bot_down)     { Bot_DownedFrame(bot); return; }

	Bot_Plan(bot);
}
