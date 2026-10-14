// Choosing what a bot does: every option scored, the best one wins.
//
// A fixed rule list makes the same choice in the same situation every time,
// which is exactly what makes a bot readable in the bad way. Each score here
// combines the situation with the bot's own personality, so two bots under the
// same fire take different options. The option already running gets a bonus, so
// a bot does not flip between two close scores on every planner tick.

#define BOT_OPT_HOLD   0.15

entity Bot_FindCasualty(entity bot);   // bot/tactics.qc

void Bot_TrackTarget(entity bot, entity tgt)
{
	if (!tgt) return;

	if (vlen(tgt.origin - bot.bot_tgtLastOrg) > 48)
	{
		bot.bot_tgtLastOrg = tgt.origin;
		bot.bot_tgtStillAt = time;
	}

	vector v = tgt.velocity;
	v_z = 0;
	if (vlen(v) > 40) bot.bot_lkpDir = normalize(v);
}

void Bot_Decide(entity bot)
{
	entity tgt = bot.bot_target;
	Bot_TrackTarget(bot, tgt);

	float hp = bot.health / 100;
	if (hp > 1) hp = 1;
	float aggro = bot.bot_aggro;
	float skl = bot.bot_skill;
	float hurt = (time - bot.bot_hurtAt) < 1.5;
	float dist = tgt ? vlen(tgt.origin - bot.origin) : 0;
	float cur = bot.bot_state;

	float sRevive = 0, sRearm = 0, sCombat = 0, sCover = 0, sPeek = 0;
	float sFlank = 0, sPush = 0, sHeal = 0, sHunt = 0, sRoam = 0.2;

	if (Bot_FindCasualty(bot))
		sRevive = tgt ? 0.9 * (1 - aggro) + 0.05 : 1;

	Bot_PickupPlan(bot);
	float needs = Bot_NeedsWeapon(bot);
	float knife = tgt && needs && (dist < 260 || aggro > 0.65);   // commits to the knife

	if (needs && bot.bot_pickup) sRearm = 0.9;
	else if (bot.bot_pickup && !tgt) sRearm = 0.45;
	if (knife) sRearm = 0;

	bot.bot_breakUntil = 0;
	if (tgt)
	{
		sCombat = 0.55 + aggro * 0.2 + hp * 0.2;

		if (needs && !knife)
		{
			// Nothing to fight back with and no stomach for a knife fight.
			sCombat = 0;
			bot.bot_breakUntil = time + 2.5;
			if (!bot.bot_pickup) sRearm = 0.6;
		}

		float exposure = (1 - hp) * 0.7 + (hurt ? 0.3 : 0) + (bot.reload ? 0.35 : 0);
		sCover = exposure * (1.1 - aggro * 0.5);

		if (cur == BSTATE_COVER || cur == BSTATE_PEEK)
			if (WP_Live(bot.bot_peekNode) && !bot.reload && hp > 0.35 && time > bot.bot_peekAt)
				sPeek = 0.8;

		float still = time - bot.bot_tgtStillAt;
		if (still > 2.5 && dist > 350 && aggro > 0.35 && skl > 0.3 && WP_Ready())
			if (time > bot.bot_flankUntil + 6) sFlank = 0.55 + aggro * 0.3;
		if (time < bot.bot_flankUntil) sFlank = 0.8;

		if ((tgt.reload || tgt.health < 35) && hp > 0.4) sPush = 0.72 + aggro * 0.25;
	}

	if (hp < 0.35 && bot.medkits > 0 && (!tgt || dist > 500)) sHeal = 0.85;
	if (!tgt && bot.bot_lkp != '0 0 0') sHunt = 0.5;

	if (cur == BSTATE_REVIVE) sRevive = sRevive + BOT_OPT_HOLD;
	if (cur == BSTATE_REARM)  sRearm  = sRearm  + BOT_OPT_HOLD;
	if (cur == BSTATE_COMBAT) sCombat = sCombat + BOT_OPT_HOLD;
	if (cur == BSTATE_COVER)  sCover  = sCover  + BOT_OPT_HOLD;
	if (cur == BSTATE_PEEK)   sPeek   = sPeek   + BOT_OPT_HOLD;
	if (cur == BSTATE_PUSH)   sPush   = sPush   + BOT_OPT_HOLD;
	if (cur == BSTATE_HEAL)   sHeal   = sHeal   + BOT_OPT_HOLD;
	if (cur == BSTATE_HUNT)   sHunt   = sHunt   + BOT_OPT_HOLD;

	float best = BSTATE_ROAM;
	float bestScore = sRoam;
	if (sHunt   > bestScore) { bestScore = sHunt;   best = BSTATE_HUNT; }
	if (sRearm  > bestScore) { bestScore = sRearm;  best = BSTATE_REARM; }
	if (sCombat > bestScore) { bestScore = sCombat; best = BSTATE_COMBAT; }
	if (sCover  > bestScore) { bestScore = sCover;  best = BSTATE_COVER; }
	if (sPeek   > bestScore) { bestScore = sPeek;   best = BSTATE_PEEK; }
	if (sFlank  > bestScore) { bestScore = sFlank;  best = BSTATE_FLANK; }
	if (sPush   > bestScore) { bestScore = sPush;   best = BSTATE_PUSH; }
	if (sHeal   > bestScore) { bestScore = sHeal;   best = BSTATE_HEAL; }
	if (sRevive > bestScore) { bestScore = sRevive; best = BSTATE_REVIVE; }

	if (best != cur)
	{
		if (best == BSTATE_FLANK) bot.bot_flankUntil = time + 6;
		if (best == BSTATE_PEEK)  bot.bot_peekUntil  = time + random(0.9, 1.6);
		if (best == BSTATE_HUNT)  bot.bot_searchLeft = 3;
	}
	bot.bot_state = best;
}
