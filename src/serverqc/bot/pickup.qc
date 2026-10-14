// Walking to a dropped weapon or a box of ammunition.
//
// Items here are touch pickups, so a bot only has to stand on one: no USE
// press, no release between pickups, which is most of what this file is in
// QUALKER. What is left is deciding whether anything on the floor is worth the
// walk, and holding that choice steady while it walks.

#define BOT_PICKUP_SCAN  1200   // how far a bot will go for a weapon
#define BOT_PICKUP_RATE  0.6    // seconds between scans
#define BOT_PICKUP_GIVEUP 8     // seconds before a chosen item is abandoned

float Bot_PickupWid(entity it)
{
	if (!it.weapon) return WID_NONE;
	return Weapon_IDFromBit(it.weapon);
}

// A gun with something to fire. The crowbar does not count: a bot that calls it
// a weapon never goes looking for a real one.
float Bot_HasLiveGun(entity bot)
{
	for (float wid = 1; wid < WID_COUNT; wid = wid + 1)
	{
		if (wid == WID_CROWBAR) continue;
		if (bot_wpnClass[wid] == WCLASS_OTHER) continue;
		if (!Bot_Owns(bot, wid)) continue;
		if (Bot_ClipLeft(bot, wid) > 0) return TRUE;
		if (Bot_PoolLeft(bot, wid) > 0) return TRUE;
	}
	return FALSE;
}

float Bot_NeedsWeapon(entity bot)
{
	return !Bot_HasLiveGun(bot);
}

// Worth walking to, and how badly. Negative means leave it.
float Bot_PickupScore(entity bot, entity it, float dist)
{
	if (dist > BOT_PICKUP_SCAN) return -1;
	if (it == bot.bot_pickupBad && time < bot.bot_pickupBadUntil) return -1;
	if (it.solid != SOLID_TRIGGER) return -1;   // already taken, waiting to respawn
	if (it.classname == "") return -1;

	float score = -1;
	float wid = Bot_PickupWid(it);

	if (wid > WID_NONE && wid < WID_COUNT && bot_wpnClass[wid] != WCLASS_OTHER)
	{
		// A gun it cannot use yet is worth far more than a better one it has.
		if (!Bot_Owns(bot, wid)) score = 900 + bot_wpnRange[wid] * 0.1;
		else if (Bot_PoolLeft(bot, wid) <= 0) score = 500;
		else score = 120;
	}
	else if (substring(it.classname, 0, 5) == "ammo_" || it.classname == "item_box")
	{
		score = Bot_NeedsWeapon(bot) ? 150 : 300;
	}
	else if (it.classname == "item_healthkit" || it.classname == "item_battery")
	{
		float miss = bot.max_health - bot.health;
		if (it.classname == "item_battery") miss = 100 - bot.armorvalue;
		if (miss < 25) return -1;
		score = 200 + miss;
	}

	if (score < 0) return -1;
	if (Bot_NeedsWeapon(bot)) score = score + 400;
	return score - dist * 0.35;
}

entity Bot_FindPickup(entity bot)
{
	entity best = world;
	float bestScore = 0;

	for (entity e = findradius(bot.origin, BOT_PICKUP_SCAN); e; e = e.chain)
	{
		if (e == bot) continue;
		if (e.owner == bot) continue;

		float s = Bot_PickupScore(bot, e, vlen(e.origin - bot.origin));
		if (s > bestScore) { bestScore = s; best = e; }
	}
	return best;
}

// TRUE while the bot is still going for it.
float Bot_PickupStep(entity bot, entity it)
{
	if (!it || wasfreed(it)) return FALSE;
	if (it.solid != SOLID_TRIGGER) { bot.bot_pickup = world; return FALSE; }
	if (time > bot.bot_pickupGiveUp)
	{
		// Could not get there in time: usually an item the graph cannot reach.
		// Remember it for a while, or the next plan picks the same one again.
		bot.bot_pickupBad = it;
		bot.bot_pickupBadUntil = time + 30;
		bot.bot_pickup = world;
		return FALSE;
	}

	// Standing on it is the pickup, so this is only ever a walk, but it still
	// has to go round the geometry: straight at it wedges on the first corner.
	if (Bot_FollowPath(bot, it.origin, 1)) return TRUE;

	// No route to it. Close by that is fine, the last few units are a step; far
	// away it means the graph cannot get there, so stop pushing into the wall.
	if (vlen(it.origin - bot.origin) > 200)
	{
		bot.bot_pickupBad = it;
		bot.bot_pickupBadUntil = time + 30;
		bot.bot_pickup = world;
		return FALSE;
	}

	Bot_MoveTo(bot, it.origin, 1);
	return TRUE;
}

void Bot_PickupPlan(entity bot)
{
	if (bot.bot_pickup && !wasfreed(bot.bot_pickup)
	    && bot.bot_pickup.solid == SOLID_TRIGGER
	    && time < bot.bot_pickupGiveUp)
	{
		if (time < bot.bot_pickupAt) return;
	}

	bot.bot_pickupAt = time + BOT_PICKUP_RATE;

	entity want = Bot_FindPickup(bot);
	if (want != bot.bot_pickup)
	{
		bot.bot_pickup = want;
		bot.bot_pickupGiveUp = time + BOT_PICKUP_GIVEUP;
	}
}
