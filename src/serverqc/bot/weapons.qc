// What the AI knows about each weapon, which the registry does not carry.
//
// The weapon registry has no range, no magazine and no ammunition pool: all
// three are defines private to each weapon file. This table is that gap, and it
// lives here rather than in weapondefs.qc, which is compiled into the client
// and the menu as well and would pay for data neither reads.

#define WCLASS_MELEE    0
#define WCLASS_PISTOL   1
#define WCLASS_SMG      2
#define WCLASS_RIFLE    3
#define WCLASS_SHOTGUN  4
#define WCLASS_SNIPER   5
#define WCLASS_OTHER    6

float bot_wpnClass[WID_COUNT];
float bot_wpnRange[WID_COUNT];   // preferred engagement distance
float bot_wpnBurst[WID_COUNT];   // shots per trigger pull, 0 means hold it down
float bot_wpnReady;

void BotWeapon_Set(float wid, float cls, float range, float burst)
{
	if (wid <= WID_NONE || wid >= WID_COUNT) return;
	bot_wpnClass[wid] = cls;
	bot_wpnRange[wid] = range;
	bot_wpnBurst[wid] = burst;
}

void BotWeapon_RegistryInit()
{
	if (bot_wpnReady) return;
	bot_wpnReady = TRUE;

	for (float i = 0; i < WID_COUNT; i = i + 1)
	{
		bot_wpnClass[i] = WCLASS_OTHER;
		bot_wpnRange[i] = 600;
		bot_wpnBurst[i] = 3;
	}

	BotWeapon_Set(WID_CROWBAR,   WCLASS_MELEE,     60, 0);
	BotWeapon_Set(WID_GLOCK,     WCLASS_PISTOL,   450, 2);
	BotWeapon_Set(WID_PYTHON,    WCLASS_PISTOL,   700, 1);
	BotWeapon_Set(WID_MP5,       WCLASS_SMG,      800, 4);
	BotWeapon_Set(WID_SHOTGUN,   WCLASS_SHOTGUN,  320, 1);
	BotWeapon_Set(WID_CROSSBOW,  WCLASS_SNIPER,  1500, 1);
	BotWeapon_Set(WID_GAUSS,     WCLASS_RIFLE,    900, 1);
	BotWeapon_Set(WID_EGON,      WCLASS_RIFLE,    500, 0);
	BotWeapon_Set(WID_HORNETGUN, WCLASS_RIFLE,    700, 3);
	// Thrown and placed weapons, the RPG's slow rocket and the snarks are left
	// as OTHER: the fight code never picks one, so a bot does not stand there
	// arming a tripmine in a gunfight.
}

// The registry stores neither, so both are a switch over the ids above.
float Bot_ClipLeft(entity bot, float wid)
{
	if (wid == WID_GLOCK)    return bot.glock_clip;
	if (wid == WID_PYTHON)   return bot.python_clip;
	if (wid == WID_MP5)      return bot.mp5_clip;
	if (wid == WID_SHOTGUN)  return bot.shotgun_clip;
	if (wid == WID_CROSSBOW) return bot.crossbow_clip;
	if (wid == WID_RPG)      return bot.rpg_clip;
	return 1;      // no magazine: it draws straight from the pool
}

float Bot_PoolLeft(entity bot, float wid)
{
	if (wid == WID_GLOCK)     return bot.ammo9x19;
	if (wid == WID_MP5)       return bot.ammo9x19;
	if (wid == WID_PYTHON)    return bot.ammo357;
	if (wid == WID_SHOTGUN)   return bot.ammoShells;
	if (wid == WID_CROSSBOW)  return bot.ammoBolts;
	if (wid == WID_RPG)       return bot.ammoRockets;
	if (wid == WID_GAUSS)     return bot.ammoUranium;
	if (wid == WID_EGON)      return bot.ammoUranium;
	if (wid == WID_HORNETGUN) return bot.ammoHornets;
	return 1;      // melee and anything without a pool
}

float Bot_HasClip(float wid)
{
	return wid == WID_GLOCK || wid == WID_PYTHON || wid == WID_MP5
	    || wid == WID_SHOTGUN || wid == WID_CROSSBOW || wid == WID_RPG;
}

float Bot_MaxClip(float wid)
{
	if (wid == WID_GLOCK)    return 17;
	if (wid == WID_PYTHON)   return 6;
	if (wid == WID_MP5)      return 50;
	if (wid == WID_SHOTGUN)  return 8;
	if (wid == WID_CROSSBOW) return 5;
	if (wid == WID_RPG)      return 1;
	return 0;
}

float Bot_Owns(entity bot, float wid)
{
	if (wid <= WID_NONE || wid >= WID_COUNT) return FALSE;
	return (bot.weapons & weapon_bit[wid]) != 0;
}
