
#define WEAPONBOX_MODEL "models/w_weaponbox.iqm"

void WeaponBox_Touch();

void WeaponBox_Precache()
{
	precache_model(WEAPONBOX_MODEL);
}

void WeaponBox_CopyClipFor(entity dst, entity src, float weaponBit)
{
	if (weaponBit == WEAPON_GLOCK)         dst.glock_clip    = src.glock_clip;
	else if (weaponBit == WEAPON_PYTHON)   dst.python_clip   = src.python_clip;
	else if (weaponBit == WEAPON_MP5)      dst.mp5_clip      = src.mp5_clip;
	else if (weaponBit == WEAPON_SHOTGUN)  dst.shotgun_clip  = src.shotgun_clip;
	else if (weaponBit == WEAPON_CROSSBOW) dst.crossbow_clip = src.crossbow_clip;
	else if (weaponBit == WEAPON_RPG)      dst.rpg_clip      = src.rpg_clip;
}

void WeaponBox_PackFromPlayer(entity box, entity p)
{
	box.weapons = p.weapons & ~WEAPON_SUIT;

	box.glock_clip    = p.glock_clip;
	box.python_clip   = p.python_clip;
	box.mp5_clip      = p.mp5_clip;
	box.shotgun_clip  = p.shotgun_clip;
	box.crossbow_clip = p.crossbow_clip;
	box.rpg_clip      = p.rpg_clip;

	box.ammo9x18      = p.ammo9x18;
	box.ammo9x19      = p.ammo9x19;
	box.ammo357       = p.ammo357;
	box.ammo545x39    = p.ammo545x39;
	box.ammo9x39      = p.ammo9x39;
	box.ammo762x39    = p.ammo762x39;
	box.ammo762x54    = p.ammo762x54;
	box.ammoBat       = p.ammoBat;
	box.ammoShells    = p.ammoShells;
	box.ammoGrenades  = p.ammoGrenades;
	box.ammoVog       = p.ammoVog;
	box.ammoBolts     = p.ammoBolts;
	box.ammoRockets   = p.ammoRockets;
	box.ammoSatchels  = p.ammoSatchels;
	box.ammoTripmines = p.ammoTripmines;
	box.ammoUranium   = p.ammoUranium;
	box.ammoHornets   = p.ammoHornets;
	box.ammoSnarks    = p.ammoSnarks;
}

float WeaponBox_IsEmpty(entity box)
{
	if (box.weapons & ~WEAPON_SUIT) return FALSE;
	if (box.ammo9x18 || box.ammo9x19 || box.ammo357 || box.ammo545x39) return FALSE;
	if (box.ammo9x39 || box.ammo762x39 || box.ammo762x54 || box.ammoBat) return FALSE;
	if (box.ammoShells || box.ammoGrenades || box.ammoVog || box.ammoBolts) return FALSE;
	if (box.ammoRockets || box.ammoSatchels || box.ammoTripmines) return FALSE;
	if (box.ammoUranium || box.ammoHornets || box.ammoSnarks) return FALSE;
	return TRUE;
}

void WeaponBox_LandThink()
{
	if (self.flags & FL_ONGROUND)
	{
		Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 95 + random() * 29, "items/weapondrop1.wav");
		return;
	}
	self.think = WeaponBox_LandThink;
	self.nextthink = time + 0.1;
}

entity WeaponBox_Spawn(vector org, vector vel)
{
	WeaponBox_Precache();

	entity box = spawn();
	box.classname = "weaponbox";
	box.movetype  = MOVETYPE_TOSS;
	box.solid     = SOLID_TRIGGER;
	setorigin(box, org);
	setmodel(box, WEAPONBOX_MODEL);
	setsize(box, '0 0 0', '0 0 0');
	box.velocity  = vel;
	box.touch     = WeaponBox_Touch;
	box.think     = WeaponBox_LandThink;
	box.nextthink = time + 0.1;
	return box;
}

void WeaponBox_Touch()
{
	if (!(self.flags & FL_ONGROUND)) return;
	if (other.classname != "player") return;
	if (other.health <= 0) return;


	other.ammo9x18      += self.ammo9x18;
	other.ammo9x19      += self.ammo9x19;
	other.ammo357       += self.ammo357;
	other.ammo545x39    += self.ammo545x39;
	other.ammo9x39      += self.ammo9x39;
	other.ammo762x39    += self.ammo762x39;
	other.ammo762x54    += self.ammo762x54;
	other.ammoBat       += self.ammoBat;
	other.ammoShells    += self.ammoShells;
	other.ammoGrenades  += self.ammoGrenades;
	other.ammoVog       += self.ammoVog;
	other.ammoBolts     += self.ammoBolts;
	other.ammoRockets   += self.ammoRockets;
	other.ammoSatchels  += self.ammoSatchels;
	other.ammoTripmines += self.ammoTripmines;
	other.ammoUranium   += self.ammoUranium;
	other.ammoHornets   += self.ammoHornets;
	other.ammoSnarks    += self.ammoSnarks;

	float bits = self.weapons & ~WEAPON_SUIT;
	float i;
	for (i = 0; i < MAX_WEAPONS; i = i + 1)
	{
		float bit = pow(2, i);
		if (bit > bits) break;
		if (!(bits & bit)) continue;
		if (!(other.weapons & bit))
		{
			other.weapons = other.weapons | bit;
			other.items   = other.items   | bit;
			WeaponBox_CopyClipFor(other, self, bit);
		}
	}

	Ammo_SyncHUD(other);
	Sound_Play(other, CHAN_ITEM, 1, ATTN_NORM, PITCH_NORM, "items/gunpickup2.wav");
	stuffcmd(other, "bf\n");

	self.touch = SUB_Null;
	remove(self);
}

void weaponbox()
{
	WeaponBox_Precache();
	self.movetype = MOVETYPE_TOSS;
	self.solid    = SOLID_TRIGGER;
	setmodel(self, WEAPONBOX_MODEL);
	setsize(self, '0 0 0', '0 0 0');
	self.touch    = WeaponBox_Touch;
}
