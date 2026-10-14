
void Player_StripWeapons(entity p)
{
	if (!p || p.classname != "player") return;

	p.weapons = p.weapons & WEAPON_SUIT;

	p.ammo9x18      = 0;
	p.ammo9x19      = 0;
	p.ammo357       = 0;
	p.ammo545x39    = 0;
	p.ammo9x39      = 0;
	p.ammo762x39    = 0;
	p.ammo762x54    = 0;
	p.ammoBat       = 0;
	p.ammoShells    = 0;
	p.ammoGrenades  = 0;
	p.ammoVog       = 0;
	p.ammoBolts     = 0;
	p.ammoRockets   = 0;
	p.ammoSatchels  = 0;
	p.ammoTripmines = 0;
	p.ammoUranium   = 0;
	p.ammoHornets   = 0;
	p.ammoSnarks    = 0;

	p.glock_clip    = 0;
	p.python_clip   = 0;
	p.mp5_clip      = 0;
	p.shotgun_clip  = 0;
	p.crossbow_clip = 0;
	p.rpg_clip      = 0;
	p.currentClip   = 0;
	p.currentammo   = 0;

	p.glock_pickup       = 0;
	p.python_pickup      = 0;
	p.mp5_pickup         = 0;
	p.shotgun_pickup     = 0;
	p.crossbow_pickup    = 0;
	p.handgrenade_pickup = 0;
	p.rpg_pickup         = 0;
	p.satchel_pickup     = 0;
	p.tripmine_pickup    = 0;
	p.gauss_pickup       = 0;
	p.egon_pickup        = 0;
	p.hgun_pickup        = 0;
	p.snark_pickup       = 0;

	p.weapon       = WEAPON_NONE;
	Viewmodel_Hide(p);
	p.weaponframe  = 0;
	p.weaponSelect  = SUB_Null;
	p.weaponAttack  = SUB_Null;
	p.weaponAttack2 = SUB_Null;
	p.weaponReload  = SUB_Null;
	p.weaponSwitch  = SUB_Null;
	p.reload          = FALSE;
	p.attack_finished = 0;

	entity oself = self;
	self = p;
	Weapon_Update();
	self = oself;
}

void PlayerWeaponStrip_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	entity p;
	if (pActivator && pActivator.classname == "player")
		p = pActivator;
	else
		p = find(world, classname, "player");
	if (p) Player_StripWeapons(p);
}

void PlayerWeaponStrip_Use()
{
	entity p;
	if (activator && activator.classname == "player")
		p = activator;
	else
		p = find(world, classname, "player");
	if (p) Player_StripWeapons(p);
}

void player_weaponstrip()
{
	self.solid    = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.model    = "";
	self.use      = PlayerWeaponStrip_Use;
	self.usehl    = PlayerWeaponStrip_UseHL;
}
