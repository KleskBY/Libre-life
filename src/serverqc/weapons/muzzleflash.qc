// Muzzle flash sprites, first and third person. See docs/guide/07-weapons.md,
// "Third person weapon effects".

entity Sprite_Create(string pSpriteName, vector origin, float animate);

#define MUZZLE_SPRITE       "sprites/muzzleflash.spr"
#define MUZZLE_WORLD_SCALE  0.35   // third person sprite, before the holder's scale

void Muzzle_Precache()
{
	precache_model(MUZZLE_SPRITE);
}

entity Muzzle_Sprite(entity shooter, vector org, float scl)
{
	entity f = Sprite_Create(MUZZLE_SPRITE, org, TRUE);   // spawns its own entity
	f.movetype = MOVETYPE_NONE;
	f.solid = SOLID_NOT;
	f.owner = shooter;
	f.effects = EF_FULLBRIGHT | EF_ADDITIVE;
	f.scale = scl;
	setsize(f, '0 0 0', '0 0 0');
	setorigin(f, org);
	f.angles_z = random(0, 359);
	f.nextthink = time + 0.05;
	f.think = SUB_Remove;
	return f;
}

// First person flash, called by the weapon with a viewmodel space origin.
void Weapon_Muzzleflash(vector org, float scl)
{
	self.effects = self.effects | EF_MUZZLEFLASH;
	entity f = Muzzle_Sprite(self, org, scl);
	f.viewmodelforclient = self;   // view relative, drawn to the shooter only
	f.alpha = 0.7;
}

// Third person flash at the barrel of the held world weapon, for everyone but the
// shooter. Run once per shot from Weapon_Attack, keyed off EF_MUZZLEFLASH, so it
// fires even when a scoped weapon skips its first person sprite.
void Weapon_MuzzleflashWorld()
{
	if (!(self.effects & EF_MUZZLEFLASH)) return;
	if (!Weapon_WorldMuzzle(self)) return;

	float psc = self.scale;
	if (!psc) psc = 1;
	entity f = Muzzle_Sprite(self, g_fxMuzzle, MUZZLE_WORLD_SCALE * psc);
	f.alpha = 0.85;
	f.customizeentityforclient = Effect_HideFromOwner;
}

// For a monster whose gun is part of its own mesh: the flash sits off the right
// hand bone along the aim, and the casing leaves up and to the right. Drawn to
// everyone, since a monster is nobody's first person view.
void Monster_MuzzleEffects(entity mon, vector aimDir, float gunLen, string shellMdl)
{
	float msc = mon.scale;
	if (!msc) msc = 1;

	vector hand = mon.origin + mon.view_ofs * 0.7;
	float tag = gettagindex(mon, "Bip01 R Hand");
	if (tag > 0) hand = gettaginfo(mon, tag);

	vector a = vectoangles(aimDir);
	makevectors([0 - a_x, a_y, 0]);   // vectoangles and makevectors disagree on pitch sign
	g_fxFwd   = v_forward;
	g_fxRight = v_right;
	g_fxUp    = v_up;

	Muzzle_Sprite(mon, hand + g_fxFwd * gunLen * msc, MUZZLE_WORLD_SCALE * msc);

	if (shellMdl == "") return;
	vector port = hand + g_fxFwd * (gunLen * 0.3 * msc) + g_fxRight * (3 * msc) + g_fxUp * (3 * msc);
	vector vel = g_fxRight * random(60, 110) + g_fxUp * random(60, 100) + g_fxFwd * random(0, 15);
	Shell_Spawn(mon, shellMdl, port, vel);
}
