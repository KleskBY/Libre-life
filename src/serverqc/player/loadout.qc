
void GamePlayerEquip_EquipPlayer(entity player);	// func/game_player_equip.qc

// Strip everything a multiplayer respawn must not inherit from the last life.
// The suit bit is dropped too; Loadout_ApplyForMode hands it straight back.
void Loadout_ClearInventory(entity p)
{
	if (!p) return;

	p.weapons     = 0;
	p.items       = 0;
	p.weapon      = 0;
	p.currentClip = 0;
	p.weaponSelect = __NULL__;

	// A reload finishes through the player's think, and dying replaces that
	// think. Without this a player killed mid reload respawns with .reload set
	// and can never fire or switch, and the viewmodel replays the reload.
	p.reload      = FALSE;
	p.blockSwitch = FALSE;
	p.weaponframe = 0;
	Sound_CancelDelayed(p);

	p.glock_clip    = 0;
	p.python_clip   = 0;
	p.mp5_clip      = 0;
	p.shotgun_clip  = 0;
	p.crossbow_clip = 0;
	p.rpg_clip      = 0;

	p.glock_pickup    = 0;
	p.python_pickup   = 0;
	p.mp5_pickup      = 0;
	p.shotgun_pickup  = 0;
	p.crossbow_pickup = 0;
	p.handgrenade_pickup = 0;
	p.rpg_pickup      = 0;
	p.satchel_pickup  = 0;
	p.tripmine_pickup = 0;
	p.gauss_pickup    = 0;
	p.egon_pickup     = 0;
	p.hgun_pickup     = 0;
	p.snark_pickup    = 0;

	p.ammo9x18     = 0;
	p.ammo9x19     = 0;
	p.ammo357      = 0;
	p.ammo545x39   = 0;
	p.ammo9x39     = 0;
	p.ammo762x39   = 0;
	p.ammo762x54   = 0;
	p.ammoBat      = 0;
	p.ammoShells   = 0;
	p.ammoGrenades = 0;
	p.ammoVog      = 0;
	p.ammoBolts    = 0;
	p.ammoRockets  = 0;
	p.ammoSatchels = 0;
	p.ammoTripmines= 0;
	p.ammoUranium  = 0;
	p.ammoHornets  = 0;
	p.ammoSnarks   = 0;
}

void GiveStarterWeapons(entity p)
{
	p.weapons = p.weapons | WEAPON_CROWBAR | WEAPON_GLOCK;
	p.items   = p.items   | WEAPON_CROWBAR | WEAPON_GLOCK;

	p.glock_clip   = GLOCK_MAX_CLIP;
	p.glock_pickup = 1;
	p.ammo9x19     = 68;

	p.weapon       = WEAPON_GLOCK;
	p.currentClip  = p.glock_clip;
}

// runs every game_player_equip over the spawning player and, if there was at
// least one, skips the default kit entirely.
// GamePlayerEquip_EquipPlayer reads the list off `self`, so swap it per entity.
float Loadout_ApplyEquipEnts(entity p)
{
	float found = FALSE;
	entity oself = self;

	for (entity e = find(world, classname, "game_player_equip"); e;
	     e = find(e, classname, "game_player_equip"))
	{
		found = TRUE;
		self = e;
		GamePlayerEquip_EquipPlayer(p);
	}

	self = oself;
	return found;
}

// Starting equipment for a player who arrived with no transfer to restore.
// Sets starting equipment for a player who arrived with no transfer
void Loadout_ApplyForMode(entity p)
{
	if (cvar("gamemode") == MODE_SP)
	{
		// Unchanged single-player behaviour: id1 maps hand out the starter kit,
		// Maps expect the map itself to arm you
		if (Map_IsId1BSP()) GiveStarterWeapons(p);
		return;
	}

	// Multiplayer always spawns you suited.
	p.weapons = p.weapons | WEAPON_SUIT;

	if (Loadout_ApplyEquipEnts(p)) return;

	GiveStarterWeapons(p);
}

// GR_PLR_DROP_GUN_ACTIVE / GR_PLR_DROP_AMMO_ACTIVE: on death in multiplayer
// the gun you were holding, plus the ammo pool it draws from, goes into a
// weaponbox at the corpse. The crowbar is never dropped.
void PackDeadPlayerItems(entity p)
{
	if (!p) return;

	float bit = p.weapon;
	if (bit == 0 || bit == WEAPON_SUIT || bit == WEAPON_CROWBAR) return;
	if (!(p.weapons & bit)) return;

	entity box = WeaponBox_Spawn(p.origin + '0 0 16',
		[random() * 200 - 100, random() * 200 - 100, random() * 100 + 100]);

	box.weapons = bit;
	WeaponBox_CopyClipFor(box, p, bit);

	// 9mm is shared by the glock and the MP5; hand grenades share ammoGrenades
	// with the MP5's secondary, so that pool deliberately stays with the player.
	if (bit == WEAPON_GLOCK || bit == WEAPON_MP5)
		{ box.ammo9x19 = p.ammo9x19; p.ammo9x19 = 0; }
	else if (bit == WEAPON_PYTHON)
		{ box.ammo357 = p.ammo357; p.ammo357 = 0; }
	else if (bit == WEAPON_SHOTGUN)
		{ box.ammoShells = p.ammoShells; p.ammoShells = 0; }
	else if (bit == WEAPON_CROSSBOW)
		{ box.ammoBolts = p.ammoBolts; p.ammoBolts = 0; }
	else if (bit == WEAPON_RPG)
		{ box.ammoRockets = p.ammoRockets; p.ammoRockets = 0; }
	else if (bit == WEAPON_GAUSS || bit == WEAPON_EGON)
		{ box.ammoUranium = p.ammoUranium; p.ammoUranium = 0; }
	else if (bit == WEAPON_HORNETGUN)
		{ box.ammoHornets = p.ammoHornets; p.ammoHornets = 0; }
	else if (bit == WEAPON_HANDGRENADE)
		{ box.ammoGrenades = p.ammoGrenades; p.ammoGrenades = 0; }
	else if (bit == WEAPON_SATCHEL)
		{ box.ammoSatchels = p.ammoSatchels; p.ammoSatchels = 0; }
	else if (bit == WEAPON_TRIPMINE)
		{ box.ammoTripmines = p.ammoTripmines; p.ammoTripmines = 0; }
	else if (bit == WEAPON_SNARK)
		{ box.ammoSnarks = p.ammoSnarks; p.ammoSnarks = 0; }

	p.weapons = p.weapons & ~bit;
	p.items   = p.items   & ~bit;

	if (WeaponBox_IsEmpty(box)) remove(box);
}
