
void Flashlight_Enable();
void PlayerTransfer_Clear();
float Player_SlotIndex(entity p);

// Cross-level inventory carry, keyed by client slot.
//
// Cvars are the only state that survives changelevel, so fields are mirrored into "xfer<slot>_<name>"
// The unsuffixed "xfer_valid" stays a global "a transfer was staged by the last
// changelevel" flag. worldspawn (main.qc) uses it to tell a level transition
// apart from a fresh start. Per-slot "xfer<slot>_valid" gates the actual load.

#define MAX_XFER_SLOTS 32

string PlayerTransfer_Key(float slot, string name)
{
	return strcat("xfer", ftos(slot), "_", name);
}

void PlayerTransfer_SetS(float slot, string name, string val)
{
	string cv = PlayerTransfer_Key(slot, name);
	RegisterCvar(cv, "");
	cvar_set(cv, val);
}

void PlayerTransfer_SetF(float slot, string name, float val)
{
	PlayerTransfer_SetS(slot, name, ftos(val));
}

float PlayerTransfer_GetF(float slot, string name)
{
	string cv = PlayerTransfer_Key(slot, name);
	RegisterCvar(cv, "");
	return cvar(cv);
}

string PlayerTransfer_GetS(float slot, string name)
{
	string cv = PlayerTransfer_Key(slot, name);
	RegisterCvar(cv, "");
	return cvar_string(cv);
}

void PlayerTransfer_ClearFor(float slot)
{
	PlayerTransfer_SetS(slot, "valid", "0");

	PlayerTransfer_SetS(slot, "health", "");
	PlayerTransfer_SetS(slot, "max_health", "");
	PlayerTransfer_SetS(slot, "armorvalue", "");
	PlayerTransfer_SetS(slot, "armortype", "");

	PlayerTransfer_SetS(slot, "weapons", "");
	PlayerTransfer_SetS(slot, "items", "");
	PlayerTransfer_SetS(slot, "weapon", "");
	PlayerTransfer_SetS(slot, "currentclip", "");
	PlayerTransfer_SetS(slot, "glock_clip", "");
	PlayerTransfer_SetS(slot, "python_clip", "");
	PlayerTransfer_SetS(slot, "mp5_clip", "");
	PlayerTransfer_SetS(slot, "shotgun_clip", "");
	PlayerTransfer_SetS(slot, "crossbow_clip", "");
	PlayerTransfer_SetS(slot, "rpg_clip", "");
	PlayerTransfer_SetS(slot, "glock_pickup", "");
	PlayerTransfer_SetS(slot, "python_pickup", "");
	PlayerTransfer_SetS(slot, "mp5_pickup", "");
	PlayerTransfer_SetS(slot, "shotgun_pickup", "");
	PlayerTransfer_SetS(slot, "crossbow_pickup", "");
	PlayerTransfer_SetS(slot, "handgrenade_pickup", "");
	PlayerTransfer_SetS(slot, "rpg_pickup", "");
	PlayerTransfer_SetS(slot, "satchel_pickup", "");
	PlayerTransfer_SetS(slot, "tripmine_pickup", "");
	PlayerTransfer_SetS(slot, "gauss_pickup", "");
	PlayerTransfer_SetS(slot, "egon_pickup", "");
	PlayerTransfer_SetS(slot, "hgun_pickup", "");
	PlayerTransfer_SetS(slot, "snark_pickup", "");

	PlayerTransfer_SetS(slot, "ammo9x18", "");
	PlayerTransfer_SetS(slot, "ammo9x19", "");
	PlayerTransfer_SetS(slot, "ammo357", "");
	PlayerTransfer_SetS(slot, "ammo545x39", "");
	PlayerTransfer_SetS(slot, "ammo9x39", "");
	PlayerTransfer_SetS(slot, "ammo762x39", "");
	PlayerTransfer_SetS(slot, "ammo762x54", "");
	PlayerTransfer_SetS(slot, "ammoBat", "");
	PlayerTransfer_SetS(slot, "ammoShells", "");
	PlayerTransfer_SetS(slot, "ammoGrenades", "");
	PlayerTransfer_SetS(slot, "ammoVog", "");
	PlayerTransfer_SetS(slot, "ammoBolts", "");
	PlayerTransfer_SetS(slot, "ammoRockets", "");
	PlayerTransfer_SetS(slot, "ammoSatchels", "");
	PlayerTransfer_SetS(slot, "ammoTripmines", "");
	PlayerTransfer_SetS(slot, "ammoUranium", "");
	PlayerTransfer_SetS(slot, "ammoHornets", "");
	PlayerTransfer_SetS(slot, "ammoSnarks", "");

	PlayerTransfer_SetS(slot, "flashlight", "");
	PlayerTransfer_SetS(slot, "flashbat", "");
	PlayerTransfer_SetS(slot, "longjump", "");
	PlayerTransfer_SetS(slot, "ducked", "");
	PlayerTransfer_SetS(slot, "airducked", "");

	// Per-slot landmark pose (written by trigger_changelevel).
	PlayerTransfer_SetS(slot, "lm_pos", "");
	PlayerTransfer_SetS(slot, "lm_angles", "");
	PlayerTransfer_SetS(slot, "lm_velocity", "");
}

float PlayerTransfer_AnyPending()
{
	for (float i = 0; i < MAX_XFER_SLOTS; i = i + 1)
		if (PlayerTransfer_GetF(i, "valid") == 1) return TRUE;
	return FALSE;
}

// Wipe every slot and the global staged flag.
void PlayerTransfer_Clear()
{
	cvar_set("xfer_valid", "0");
	for (float i = 0; i < MAX_XFER_SLOTS; i = i + 1)
		PlayerTransfer_ClearFor(i);
}

void PlayerTransfer_Save(entity p)
{
	if (!p) return;
	if (p.classname != "player")
		return;		// not a player: leave other slots alone

	float slot = Player_SlotIndex(p);

	PlayerTransfer_SetF(slot, "health",     p.health);
	PlayerTransfer_SetF(slot, "max_health", p.max_health);
	PlayerTransfer_SetF(slot, "armorvalue", p.armorvalue);
	PlayerTransfer_SetF(slot, "armortype",  p.armortype);

	// time values that become meaningless after changelevel resets time to 0).
	float persistItems = p.items & ~(IT_INVULNERABILITY | IT_INVISIBILITY | IT_QUAD | IT_SUIT);
	PlayerTransfer_SetF(slot, "weapons",     p.weapons);
	PlayerTransfer_SetF(slot, "items",       persistItems);
	PlayerTransfer_SetF(slot, "weapon",      p.weapon);
	PlayerTransfer_SetF(slot, "currentclip", p.currentClip);
	PlayerTransfer_SetF(slot, "glock_clip",  p.glock_clip);
	PlayerTransfer_SetF(slot, "python_clip", p.python_clip);
	PlayerTransfer_SetF(slot, "mp5_clip",    p.mp5_clip);
	PlayerTransfer_SetF(slot, "shotgun_clip",  p.shotgun_clip);
	PlayerTransfer_SetF(slot, "crossbow_clip", p.crossbow_clip);
	PlayerTransfer_SetF(slot, "rpg_clip",    p.rpg_clip);
	PlayerTransfer_SetF(slot, "glock_pickup",    p.glock_pickup);
	PlayerTransfer_SetF(slot, "python_pickup",   p.python_pickup);
	PlayerTransfer_SetF(slot, "mp5_pickup",      p.mp5_pickup);
	PlayerTransfer_SetF(slot, "shotgun_pickup",  p.shotgun_pickup);
	PlayerTransfer_SetF(slot, "crossbow_pickup", p.crossbow_pickup);
	PlayerTransfer_SetF(slot, "handgrenade_pickup", p.handgrenade_pickup);
	PlayerTransfer_SetF(slot, "rpg_pickup",      p.rpg_pickup);
	PlayerTransfer_SetF(slot, "satchel_pickup",  p.satchel_pickup);
	PlayerTransfer_SetF(slot, "tripmine_pickup", p.tripmine_pickup);
	PlayerTransfer_SetF(slot, "gauss_pickup",    p.gauss_pickup);
	PlayerTransfer_SetF(slot, "egon_pickup",     p.egon_pickup);
	PlayerTransfer_SetF(slot, "hgun_pickup",     p.hgun_pickup);
	PlayerTransfer_SetF(slot, "snark_pickup",    p.snark_pickup);

	PlayerTransfer_SetF(slot, "ammo9x18",    p.ammo9x18);
	PlayerTransfer_SetF(slot, "ammo9x19",    p.ammo9x19);
	PlayerTransfer_SetF(slot, "ammo357",     p.ammo357);
	PlayerTransfer_SetF(slot, "ammo545x39",  p.ammo545x39);
	PlayerTransfer_SetF(slot, "ammo9x39",    p.ammo9x39);
	PlayerTransfer_SetF(slot, "ammo762x39",  p.ammo762x39);
	PlayerTransfer_SetF(slot, "ammo762x54",  p.ammo762x54);
	PlayerTransfer_SetF(slot, "ammoBat",     p.ammoBat);
	PlayerTransfer_SetF(slot, "ammoShells",  p.ammoShells);
	PlayerTransfer_SetF(slot, "ammoGrenades",p.ammoGrenades);
	PlayerTransfer_SetF(slot, "ammoVog",     p.ammoVog);
	PlayerTransfer_SetF(slot, "ammoBolts",   p.ammoBolts);
	PlayerTransfer_SetF(slot, "ammoRockets", p.ammoRockets);
	PlayerTransfer_SetF(slot, "ammoSatchels",p.ammoSatchels);
	PlayerTransfer_SetF(slot, "ammoTripmines",p.ammoTripmines);
	PlayerTransfer_SetF(slot, "ammoUranium", p.ammoUranium);
	PlayerTransfer_SetF(slot, "ammoHornets", p.ammoHornets);
	PlayerTransfer_SetF(slot, "ammoSnarks",  p.ammoSnarks);

	// Flashlight: persist on/off state + battery charge (m_iFlashBattery).
	PlayerTransfer_SetS(slot, "flashlight", p.flashlight_on ? "1" : "0");
	PlayerTransfer_SetF(slot, "flashbat", p.flashlight_battery);

	PlayerTransfer_SetS(slot, "longjump", p.player_longJump ? "1" : "0");

	PlayerTransfer_SetS(slot, "ducked",    p.crouching ? "1" : "0");
	PlayerTransfer_SetS(slot, "airducked", p.duckedInAir ? "1" : "0");

	PlayerTransfer_SetS(slot, "valid", "1");
	cvar_set("xfer_valid", "1");
}

float PlayerTransfer_Load(entity p)
{
	if (!p) return FALSE;

	float slot = Player_SlotIndex(p);
	if (PlayerTransfer_GetF(slot, "valid") != 1) return FALSE;

	p.health     = PlayerTransfer_GetF(slot, "health");
	p.max_health = PlayerTransfer_GetF(slot, "max_health");
	p.armorvalue = PlayerTransfer_GetF(slot, "armorvalue");
	p.armortype  = PlayerTransfer_GetF(slot, "armortype");

	p.weapons     = PlayerTransfer_GetF(slot, "weapons");
	p.items       = PlayerTransfer_GetF(slot, "items");
	p.weapon      = PlayerTransfer_GetF(slot, "weapon");
	p.currentClip = PlayerTransfer_GetF(slot, "currentclip");
	p.glock_clip    = PlayerTransfer_GetF(slot, "glock_clip");
	p.python_clip   = PlayerTransfer_GetF(slot, "python_clip");
	p.mp5_clip      = PlayerTransfer_GetF(slot, "mp5_clip");
	p.shotgun_clip  = PlayerTransfer_GetF(slot, "shotgun_clip");
	p.crossbow_clip = PlayerTransfer_GetF(slot, "crossbow_clip");
	p.rpg_clip      = PlayerTransfer_GetF(slot, "rpg_clip");
	p.glock_pickup    = PlayerTransfer_GetF(slot, "glock_pickup");
	p.python_pickup   = PlayerTransfer_GetF(slot, "python_pickup");
	p.mp5_pickup      = PlayerTransfer_GetF(slot, "mp5_pickup");
	p.shotgun_pickup  = PlayerTransfer_GetF(slot, "shotgun_pickup");
	p.crossbow_pickup = PlayerTransfer_GetF(slot, "crossbow_pickup");
	p.handgrenade_pickup = PlayerTransfer_GetF(slot, "handgrenade_pickup");
	p.rpg_pickup      = PlayerTransfer_GetF(slot, "rpg_pickup");
	p.satchel_pickup  = PlayerTransfer_GetF(slot, "satchel_pickup");
	p.tripmine_pickup = PlayerTransfer_GetF(slot, "tripmine_pickup");
	p.gauss_pickup    = PlayerTransfer_GetF(slot, "gauss_pickup");
	p.egon_pickup     = PlayerTransfer_GetF(slot, "egon_pickup");
	p.hgun_pickup     = PlayerTransfer_GetF(slot, "hgun_pickup");
	p.snark_pickup    = PlayerTransfer_GetF(slot, "snark_pickup");

	p.ammo9x18    = PlayerTransfer_GetF(slot, "ammo9x18");
	p.ammo9x19    = PlayerTransfer_GetF(slot, "ammo9x19");
	p.ammo357     = PlayerTransfer_GetF(slot, "ammo357");
	p.ammo545x39  = PlayerTransfer_GetF(slot, "ammo545x39");
	p.ammo9x39    = PlayerTransfer_GetF(slot, "ammo9x39");
	p.ammo762x39  = PlayerTransfer_GetF(slot, "ammo762x39");
	p.ammo762x54  = PlayerTransfer_GetF(slot, "ammo762x54");
	p.ammoBat     = PlayerTransfer_GetF(slot, "ammoBat");
	p.ammoShells  = PlayerTransfer_GetF(slot, "ammoShells");
	p.ammoGrenades= PlayerTransfer_GetF(slot, "ammoGrenades");
	p.ammoVog     = PlayerTransfer_GetF(slot, "ammoVog");
	p.ammoBolts   = PlayerTransfer_GetF(slot, "ammoBolts");
	p.ammoRockets = PlayerTransfer_GetF(slot, "ammoRockets");
	p.ammoSatchels= PlayerTransfer_GetF(slot, "ammoSatchels");
	p.ammoTripmines= PlayerTransfer_GetF(slot, "ammoTripmines");
	p.ammoUranium = PlayerTransfer_GetF(slot, "ammoUranium");
	p.ammoHornets = PlayerTransfer_GetF(slot, "ammoHornets");
	p.ammoSnarks  = PlayerTransfer_GetF(slot, "ammoSnarks");

	p.player_longJump = (PlayerTransfer_GetF(slot, "longjump") == 1);

	p.flashlight_battery = PlayerTransfer_GetF(slot, "flashbat");
	if (PlayerTransfer_GetF(slot, "flashlight") == 1 && p.flashlight_battery > 0)
	{
		entity oself = self;
		self = p;
		Flashlight_Enable();
		self.flashlight_on = 1;
		self.flashlight_time = FLASH_DRAIN_TIME + time;
		self = oself;
	}

	if (PlayerTransfer_GetF(slot, "ducked") == 1)
	{
		p.crouching = 1;
		p.duckStartTime = time;
		if (PlayerTransfer_GetF(slot, "airducked") == 1)
		{
			p.duckedInAir = 1;
			setsize(p, PLAYER_DUCK_AIR_SIZE_MIN, PLAYER_DUCK_AIR_SIZE_MAX);
		}
		else
		{
			p.duckedInAir = 0;
			setsize(p, PLAYER_DUCK_SIZE_MIN, PLAYER_DUCK_SIZE_MAX);
		}
		p.view_ofs = DUCK_VIEW_OFS;
	}

	PlayerTransfer_ClearFor(slot);

	// worldspawn reads the global flag as "this map load was a level transition, don't wipe cross-map state". Drop it once the last client
	if (!PlayerTransfer_AnyPending())
		cvar_set("xfer_valid", "0");

	return TRUE;
}
