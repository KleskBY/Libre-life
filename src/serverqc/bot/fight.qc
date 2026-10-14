// Trigger discipline: when a bot pulls, how long it holds, and when it stops.
// The per weapon table it reads lives in bot/weapons.qc.

float Bot_PrefRange(entity bot, float wid)
{
	if (wid <= WID_NONE || wid >= WID_COUNT) return 600;
	return bot_wpnRange[wid] * bot.bot_rangePref;
}

// How good this weapon is for the range the fight is actually at.
float Bot_WeaponScore(entity bot, float wid, float dist)
{
	if (wid <= WID_NONE || wid >= WID_COUNT) return -1;
	if (!Bot_Owns(bot, wid)) return -1;

	float cls = bot_wpnClass[wid];
	if (cls == WCLASS_OTHER) return -1;

	// Out of ammunition entirely, not merely out of magazine.
	if (Bot_ClipLeft(bot, wid) <= 0 && Bot_PoolLeft(bot, wid) <= 0)
		return (cls == WCLASS_MELEE) ? 1 : -1;

	if (cls == WCLASS_MELEE) return (dist < 90) ? 500 : 1;

	float pref = Bot_PrefRange(bot, wid);
	float miss = fabs(dist - pref);
	return 4000 - miss;
}

float Bot_BestWeapon(entity bot, float dist)
{
	BotWeapon_RegistryInit();

	float best = WID_NONE;
	float bestScore = 0;

	for (float wid = 1; wid < WID_COUNT; wid = wid + 1)
	{
		float s = Bot_WeaponScore(bot, wid, dist);
		if (s > bestScore) { bestScore = s; best = wid; }
	}
	return best;
}

float Bot_WantReload(entity bot, float wid)
{
	if (wid <= WID_NONE || wid >= WID_COUNT) return FALSE;
	if (!Bot_HasClip(wid)) return FALSE;
	if (bot.reload) return FALSE;
	if (Bot_PoolLeft(bot, wid) <= 0) return FALSE;

	float left = Bot_ClipLeft(bot, wid);
	if (left <= 0) return TRUE;

	// Top up in a lull, never mid fight.
	float full = Bot_MaxClip(wid);
	if (full > 0 && left <= full * 0.25 && !bot.bot_target) return TRUE;
	return FALSE;
}

// A short trace down the aim line. This, not target selection, is what stops
// bots emptying a magazine into a team mate who walked in front of them.
float Bot_FriendlyInLine(entity bot, float dist)
{
	if (!Bot_TeamsEnabled()) return FALSE;

	makevectors(bot.v_angle);
	vector src = bot.origin + bot.view_ofs;
	traceline(src, src + v_forward * dist, FALSE, bot);
	Player_HitboxResolve();

	if (!trace_ent || trace_ent == world) return FALSE;
	if (trace_ent.classname != "player") return FALSE;
	return (trace_ent.bot_team == bot.bot_team);
}

// CAN THIS WEAPON ACTUALLY REACH, at this distance.
//
// Without this a bot swings a knife at 1500 units: the aim cone is satisfied at
// any range, and nothing else consulted distance at all.
//
// Melee is the sharp case. KNIFE_Hit tests reach when the swing RESOLVES,
// roughly a third of a second after the press, and the player knife has none of
// the slack Mutant_MeleeHit gives monsters. Swinging at the edge of its 88 units
// therefore misses anybody walking backwards, so the gate sits well inside it.
#define BOT_MELEE_REACH 62

float Bot_InEffectiveRange(entity bot, float wid, float dist)
{
	if (wid <= WID_NONE || wid >= WID_COUNT) return FALSE;

	float cls = bot_wpnClass[wid];
	if (cls == WCLASS_MELEE)   return dist <= BOT_MELEE_REACH;
	if (cls == WCLASS_OTHER)   return FALSE;

	// Pellets past twice the preferred range do nothing worth the noise.
	if (cls == WCLASS_SHOTGUN) return dist <= bot_wpnRange[wid] * 2;

	// Everything else may shoot well past its best range. A rifle at distance is
	// worse, not useless, and the spread model already charges for it.
	return dist <= bot_wpnRange[wid] * 3.5;
}

// Everything the weapon code itself refuses. Mirroring these exactly keeps the
// burst counter in step with the shots that actually leave the barrel.
float Bot_CanPullTrigger(entity bot)
{
	if (bot.reload) return FALSE;
	if (bot.bot_aimState == STATE_RUN) return FALSE;
	if (bot.tank_ent) return FALSE;
	if (time < bot.attack_finished) return FALSE;
	return TRUE;
}

// COUNT SHOTS, NOT FRAMES.
//
// The trigger is set here but the weapon does not fire until Weapon_Frame runs,
// which on the player think order is the frame AFTER this one. Decrementing the
// burst where the button is set therefore counts frames, and a bot would empty
// a magazine believing it had fired three rounds. .attack_finished only moves
// when a shot actually leaves the barrel, so watching it is the one reliable
// signal, and it is the same trick Player_NoiseFromFiring uses on the magazine.
void Bot_CountShots(entity bot)
{
	if (bot.attack_finished > bot.bot_atkFin)
	{
		if (bot.bot_burstLeft > 0)
		{
			bot.bot_burstLeft = bot.bot_burstLeft - 1;
			if (bot.bot_burstLeft <= 0)
			{
				// Aggressive bots barely pause between bursts; cautious ones let
				// the spread ramp reset.
				float lull = 0.12 + random(0, 0.3) * (1 - bot.bot_aggro);
				bot.bot_burstPause = time + lull;
			}
		}
	}
	bot.bot_atkFin = bot.attack_finished;
}

void Bot_Fight(entity bot, entity tgt, float dist)
{
	BotWeapon_RegistryInit();
	Bot_CountShots(bot);

	// A reload finishes through the player's think. Anything that replaces that
	// think first, death most of all, leaves .reload set for good, and a bot that
	// can never pull the trigger just stands and stares. No reload runs this long.
	if (bot.reload)
	{
		if (!bot.bot_reloadSince) bot.bot_reloadSince = time;
		else if (time - bot.bot_reloadSince > 5)
		{
			bot.reload = FALSE;
			bot.bot_reloadSince = 0;
		}
	}
	else
	{
		bot.bot_reloadSince = 0;
	}

	float wid = Weapon_IDFromBit(bot.weapon);

	// Change up, but not constantly: a bot that re-picks every tick spends the
	// fight drawing weapons.
	if (time > bot.bot_nextSwitch)
	{
		float want = Bot_BestWeapon(bot, dist);
		if (want > WID_NONE && want != wid)
		{
			bot.bot_armWid = want;
			bot.bot_nextSwitch = time + 2;
			bot.bot_burstLeft = 0;
			return;
		}
		bot.bot_nextSwitch = time + 0.5;
	}

	if (Bot_WantReload(bot, wid))
	{
		bot.impulse = BOT_IMPULSE_RELOAD;
		bot.bot_burstLeft = 0;
		return;
	}

	if (!tgt) return;
	if (!Bot_TargetVisible(bot, tgt))
	{
		bot.bot_burstLeft = 0;
		return;
	}
	if (!Bot_ReactReady(bot)) return;
	if (!Bot_CanPullTrigger(bot)) return;

	// Sights up when the shot is worth taking: it halves spread, and a bot that
	// never aims is strictly worse than one that does.
	float cls = bot_wpnClass[wid];
	float wantAds = (cls == WCLASS_SNIPER)
	             || (dist > 500 && cls != WCLASS_SHOTGUN && cls != WCLASS_MELEE);
	bot.button6 = wantAds;

	if (!Bot_InEffectiveRange(bot, wid, dist)) return;

	float cone = (cls == WCLASS_SHOTGUN) ? 12 : 6;
	if (cls == WCLASS_SNIPER) cone = 2.5;
	if (cls == WCLASS_MELEE)  cone = 25;
	if (!Bot_OnTarget(bot, cone)) return;

	if (Bot_FriendlyInLine(bot, dist + 64)) return;

	// A scoped shot is taken standing still, from a settled sight picture. The
	// aim velocity test is what makes it read as deliberate rather than lucky.
	if (cls == WCLASS_SNIPER)
	{
		if (vlen([bot.velocity_x, bot.velocity_y, 0]) > 40) return;
		if (vlen(bot.bot_aimVel) > 25) return;
	}

	if (time < bot.bot_burstPause) return;

	if (bot.bot_burstLeft <= 0)
	{
		float b = bot_wpnBurst[wid];
		if (b <= 0) b = 5;
		bot.bot_burstLeft = b;
	}

	// The knife swings on the SECONDARY button. KNIFE_SecondaryAttack is the
	// heavy stab: it reaches 88 units against the slash's 75, and unlike the
	// primary it carries no weapon_semiLatch, so a held button keeps swinging at
	// the attack_finished cadence instead of once per press.
	if (cls == WCLASS_MELEE) bot.button6 = TRUE;
	else                        bot.button0 = TRUE;
}
