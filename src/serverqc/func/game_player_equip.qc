// Map keys: each key is an item classname, value is a count (>=1).
//   weapon_357 "1"
//   ammo_357   "6"
//   item_battery "2"
//   ... up to MAX_EQUIP entries
//
#define SF_PLAYEREQUIP_USE_ONLY     0x0001
#define MAX_EQUIP                  32

.string equipNames [MAX_EQUIP];
.float  equipCounts[MAX_EQUIP];

float GamePlayerEquip_UseOnly() { return self.spawnflags & SF_PLAYEREQUIP_USE_ONLY; }

// Forward declarations for all resolvable classnames.
void weapon_crowbar();
void weapon_9mmhandgun();
void weapon_357();
void weapon_9mmAR();
void weapon_mp5();
void weapon_shotgun();
void weapon_crossbow();
void weapon_rpg();
void weapon_gauss();
void weapon_egon();
void weapon_hornetgun();
void weapon_handgrenade();
void weapon_satchel();
void weapon_tripmine();
void weapon_snark();
void ammo_glockclip();
void ammo_9mmclip();
void ammo_357();
void ammo_9mmAR();
void ammo_mp5clip();
void ammo_buckshot();
void ammo_crossbow();
void ammo_rpgclip();
void ammo_gaussclip();
void ammo_9mmbox();
void ammo_ARgrenades();
void ammo_mp5grenades();
void item_healthkit();
void item_battery();
void item_suit();
void item_antidote();
void item_longjump();

// Run the classname's spawn fn under self = item. Returns FALSE for unknown.
float GamePlayerEquip_RunSpawn(entity item, string cls)
{
	entity oldself = self;
	self = item;
	if      (cls == "weapon_crowbar")     weapon_crowbar();
	else if (cls == "weapon_9mmhandgun")  weapon_9mmhandgun();
	else if (cls == "weapon_357")         weapon_357();
	else if (cls == "weapon_9mmAR")       weapon_9mmAR();
	else if (cls == "weapon_mp5")         weapon_mp5();
	else if (cls == "weapon_shotgun")     weapon_shotgun();
	else if (cls == "weapon_crossbow")    weapon_crossbow();
	else if (cls == "weapon_rpg")         weapon_rpg();
	else if (cls == "weapon_gauss")       weapon_gauss();
	else if (cls == "weapon_egon")        weapon_egon();
	else if (cls == "weapon_hornetgun")   weapon_hornetgun();
	else if (cls == "weapon_handgrenade") weapon_handgrenade();
	else if (cls == "weapon_satchel")     weapon_satchel();
	else if (cls == "weapon_tripmine")    weapon_tripmine();
	else if (cls == "weapon_snark")       weapon_snark();
	else if (cls == "ammo_glockclip")     ammo_glockclip();
	else if (cls == "ammo_9mmclip")       ammo_9mmclip();
	else if (cls == "ammo_357")           ammo_357();
	else if (cls == "ammo_9mmAR")         ammo_9mmAR();
	else if (cls == "ammo_mp5clip")       ammo_mp5clip();
	else if (cls == "ammo_buckshot")      ammo_buckshot();
	else if (cls == "ammo_crossbow")      ammo_crossbow();
	else if (cls == "ammo_rpgclip")       ammo_rpgclip();
	else if (cls == "ammo_gaussclip")     ammo_gaussclip();
	else if (cls == "ammo_9mmbox")        ammo_9mmbox();
	else if (cls == "ammo_ARgrenades")    ammo_ARgrenades();
	else if (cls == "ammo_mp5grenades")   ammo_mp5grenades();
	else if (cls == "item_healthkit")     item_healthkit();
	else if (cls == "item_battery")       item_battery();
	else if (cls == "item_suit")          item_suit();
	else if (cls == "item_antidote")      item_antidote();
	else if (cls == "item_longjump")      item_longjump();
	else { self = oldself; return FALSE; }
	self = oldself;
	return TRUE;
}

void GamePlayerEquip_GrantOne(entity player, string cls)
{
	entity item = spawn();
	entity oldother = other;
	if (!GamePlayerEquip_RunSpawn(item, cls))
	{
		dprint("game_player_equip: unknown classname '"); dprint(cls); dprint("'\n");
		remove(item);
		return;
	}

	setorigin(item, player.origin);
	item.classname = cls;

	if (item.touch)
	{
		other = player;
		entity tself = self;
		self = item;
		item.touch();
		self = tself;
	}

	other = oldother;

	// Cleanup. Item_Finish leaves the entity non-solid but alive (respawn in deathmatch), so checking solidity here used to leak a hidden pickup that could reappear at the spawn point 30s later.
	if (!wasfreed(item))
		remove(item);
}

void GamePlayerEquip_EquipPlayer(entity player)
{
	if (!player) return;
	if (player.classname != "player") return;

	for (float i = 0; i < MAX_EQUIP; i = i + 1)
	{
		if (!self.equipNames[i] || self.equipNames[i] == "")
			break;
		float count = self.equipCounts[i];
		if (count < 1) count = 1;
		for (float j = 0; j < count; j = j + 1)
			GamePlayerEquip_GrantOne(player, self.equipNames[i]);
	}
}

void GamePlayerEquip_Touch()
{
	if (!Master_IsTriggered(self.master, other)) return;
	if (GamePlayerEquip_UseOnly()) return;
	GamePlayerEquip_EquipPlayer(other);
}

void GamePlayerEquip_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	GamePlayerEquip_EquipPlayer(pActivator);
}

void GamePlayerEquip_Use()
{
	GamePlayerEquip_UseHL(activator, self, useType, 0);
}

void GamePlayerEquip_PushBack(string cls, float n)
{
	for (float i = 0; i < MAX_EQUIP; i = i + 1)
	{
		if (!self.equipNames[i] || self.equipNames[i] == "")
		{
			self.equipNames[i]  = strzone(cls);
			self.equipCounts[i] = n;
			return;
		}
	}
}

void game_player_equip()
{
	self.solid    = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.effects  = EF_NODRAW;
	self.touch = GamePlayerEquip_Touch;
	self.use   = GamePlayerEquip_Use;
	self.usehl = GamePlayerEquip_UseHL;

	string key;
	float  count;
	for (float i = 1; i < (tokenize(__fullspawndata) - 1); i += 2)
	{
		key = argv(i);
		count = stof(argv(i + 1));

		if (key == "classname")  continue;
		if (key == "targetname") continue;
		if (key == "target")     continue;
		if (key == "origin")     continue;
		if (key == "angles")     continue;
		if (key == "angle")      continue;
		if (key == "model")      continue;
		if (key == "spawnflags") continue;
		if (key == "master")     continue;
		if (key == "delay")      continue;
		if (key == "killtarget") continue;
		if (key == "message")    continue;

		float hashIdx = strstrofs(key, "#", 0);
		if (hashIdx >= 0)
			key = substring(key, 0, hashIdx);

		GamePlayerEquip_PushBack(key, count);
	}
}
