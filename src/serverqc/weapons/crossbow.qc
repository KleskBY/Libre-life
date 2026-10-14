
#define CROSSBOW_DAMAGE			Skill_GetValue("sk_plr_xbow_bolt_monster", 50)
#define CROSSBOW_DAMAGE_MP		120
#define CROSSBOW_MAX_CLIP		5
#define CROSSBOW_MAX_CARRY		50
#define CROSSBOW_RATE			0.75
#define CROSSBOW_RELOAD_TIME	4.5
#define CROSSBOW_SOUND_RADIUS	2500

#define CROSSBOW_BOLT_AIR_VEL	2000
#define CROSSBOW_BOLT_WATER_VEL	1000
#define CROSSBOW_BOLT_GRAVITY	0.5
#define CROSSBOW_BOLT_STICK_TIME 10

#define CROSSBOW_VIEW_MODEL		"models/v_crossbow.iqm"
#define CROSSBOW_WORLD_MODEL	"models/w_crossbow.iqm"
#define CROSSBOW_BOLT_MODEL		"models/crossbow_bolt.iqm"

// Anims (matches crossbow_e enum)
#define CROSSBOW_IDLE1			0	// full
#define CROSSBOW_IDLE2			1	// empty
#define CROSSBOW_FIDGET1		2
#define CROSSBOW_FIDGET2		3
#define CROSSBOW_FIRE1			4	// full
#define CROSSBOW_FIRE2			5	// to-empty
#define CROSSBOW_FIRE3			6	// empty dry-fire
#define CROSSBOW_RELOAD			7
#define CROSSBOW_DRAW1			8	// full
#define CROSSBOW_DRAW2			9	// empty
#define CROSSBOW_HOLSTER1		10
#define CROSSBOW_HOLSTER2		11

#define CROSSBOW_FIRE_SOUND		"weapons/xbow_fire1.wav"
#define CROSSBOW_RELOAD_SOUND	"weapons/xbow_reload1.wav"
#define CROSSBOW_HITBOD1_SOUND	"weapons/xbow_hitbod1.wav"
#define CROSSBOW_HITBOD2_SOUND	"weapons/xbow_hitbod2.wav"
#define CROSSBOW_HITWORLD_SOUND	"weapons/xbow_hit1.wav"
#define CROSSBOW_FLY_SOUND		"weapons/xbow_fly1.wav"

#define CROSSBOW_AMMO ammoBolts
.float crossbow_clip;
.float crossbow_pickup;

//
// Crossbow bolt projectile
// Sticks to walls in single-player, explodes after impact in multiplayer.
//
void Bolt_Remove()
{
	remove(self);
}

void Bolt_Explode()
{
	T_RadiusDamage(self, self.owner, 40, 128);
	pointparticles(particleeffectnum("TE_EXPLOSION"), self.origin, '0 0 0', 1);
	remove(self);
}

void Bolt_Touch()
{
	if (other == self.owner) return;

	self.touch = SUB_Null;
	self.think = SUB_Null;
	self.nextthink = -1;

	if (other.takedamage)
	{
		T_Damage(other, self, self.owner, CROSSBOW_DAMAGE_MP, DMG_BULLET | DMG_NEVERGIB);
		Sound_Play(self, CHAN_BODY, 1, ATTN_NORM, 100, CROSSBOW_HITBOD1_SOUND, CROSSBOW_HITBOD2_SOUND);

		if (IsMultiplayer())
		{
			self.think = Bolt_Explode;
			self.nextthink = time + 0.1;
		}
		else
		{
			self.think = Bolt_Remove;
			self.nextthink = time;
		}
		return;
	}

	// Hit world / non-damageable surface
	Sound_Play(self, CHAN_BODY, 1, ATTN_NORM, PITCH_NORM, CROSSBOW_HITWORLD_SOUND);

	if (other.classname == "worldspawn" || other.solid == SOLID_BSP)
	{
		// stick into the surface for a while, then vanish
		vector dir = normalize(self.velocity);
		setorigin(self, self.origin - dir * 12);
		self.angles = vectoangles(dir);
		self.solid = SOLID_NOT;
		self.movetype = MOVETYPE_FOLLOW;
		self.aiment = other;
		self.punchangle = other.angles;
		self.view_ofs = self.origin - other.origin; // relative origin
		self.v_angle = self.angles - other.angles; // relative angles;
		self.velocity = '0 0 0';
		self.avelocity = '0 0 0';
		self.think = Bolt_Remove;
		self.nextthink = time + CROSSBOW_BOLT_STICK_TIME;
	}
	else
	{
		self.think = Bolt_Remove;
		self.nextthink = time;
	}

	if (IsMultiplayer())
	{
		self.think = Bolt_Explode;
		self.nextthink = time + 0.1;
	}
}

void Bolt_Create(entity creator, vector src, vector dir)
{
	entity bolt = spawn();
	bolt.classname = "crossbow_bolt";
	bolt.owner = creator;
	Player_ProjectileClip(bolt, creator);
	bolt.movetype = MOVETYPE_FLY;
	bolt.solid = SOLID_BBOX;
	// bolt.gravity = CROSSBOW_BOLT_GRAVITY;
	setmodel(bolt, CROSSBOW_BOLT_MODEL);
	setsize(bolt, '0 0 0', '0 0 0');
	setorigin(bolt, src);
	bolt.angles = vectoangles(dir);

	if (creator.waterlevel == 3) bolt.velocity = dir * CROSSBOW_BOLT_WATER_VEL;
	else bolt.velocity = dir * CROSSBOW_BOLT_AIR_VEL;

	bolt.avelocity_z = 10;
	bolt.touch = Bolt_Touch;
	bolt.think = Bolt_Remove;
	bolt.nextthink = time + 10;   // failsafe cleanup if it never hits anything
}

//
// Crossbow weapon
//
void CROSSBOW_ReloadFinish()
{
	Weapon_Reload(CROSSBOW_AMMO, crossbow_clip, CROSSBOW_MAX_CLIP);
	self.think = Player_Think;
	self.nextthink = time + 0.1;
}

void CROSSBOW_Reload()
{
	self.currentClip = self.crossbow_clip;
	if (self.crossbow_clip >= CROSSBOW_MAX_CLIP) return;
	if (self.CROSSBOW_AMMO <= 0)
	{
		CycleWeaponReverseCommand();
		return;
	}

	// Cancel zoom on reload
	if (self.viewzoom) self.viewzoom = 0;

	Weapon_SetFrame(CROSSBOW_RELOAD);
	self.nextthink = time + CROSSBOW_RELOAD_TIME;
	self.think = CROSSBOW_ReloadFinish;
	self.reload = TRUE;
	Sound_Play(self, CHAN_ITEM, 1, ATTN_NORM, PITCH_NORM, CROSSBOW_RELOAD_SOUND);
}

void CROSSBOW_FireBolt()
{
	if (self.crossbow_clip <= 0)
	{
		Weapon_SetFrame(CROSSBOW_FIRE3);
		self.attack_finished = time + 0.5;
		if (AUTORELOAD && self.CROSSBOW_AMMO > 0) self.impulse = 100;
		return;
	}

	self.crossbow_clip = self.crossbow_clip - 1;
	self.currentClip = self.crossbow_clip;
	Weapon_SetFrame((self.crossbow_clip > 0) ? CROSSBOW_FIRE1 : CROSSBOW_FIRE2);

	makevectors(self.v_angle + self.punchangle);
	vector src = self.origin + self.view_ofs + v_forward * 16 - v_up * 2;
	vector dir = v_forward;
	Bolt_Create(self, src, dir);

	self.punchangle_x += random(-1, -0.5);
	Sound_Play(self, CHAN_WEAPON, 1, Sound_Radius(CROSSBOW_SOUND_RADIUS), PITCH_NORM, CROSSBOW_FIRE_SOUND);

	self.attack_finished = time + CROSSBOW_RATE;
	self.think = Player_Think;
	self.nextthink = time + CROSSBOW_RATE;
}

void CROSSBOW_PrimaryAttack()
{
	CROSSBOW_FireBolt();
}

void CROSSBOW_SecondaryAttack()
{
	if (!self.viewzoom) self.viewzoom = 0.4;
	else self.viewzoom = 0;
	self.attack_finished = time + 0.5;
}

void CROSSBOW_Switch()
{
	Weapon_SetFrame(self.crossbow_clip ? CROSSBOW_DRAW1 : CROSSBOW_DRAW2);
	self.reload = TRUE;
	self.think = Player_Think;
	self.nextthink = time + 0.5;
}

void CROSSBOW_Select()
{
	if (!self.crossbow_pickup)
	{
		self.crossbow_pickup = TRUE;
		self.crossbow_clip = CROSSBOW_MAX_CLIP;
	}
	self.currentClip = self.crossbow_clip;
	self.currentammo = self.CROSSBOW_AMMO;
	self.weaponmodel = CROSSBOW_VIEW_MODEL;
	self.weaponSwitch = CROSSBOW_Switch;
	self.weaponAttack = CROSSBOW_PrimaryAttack;
	self.weaponAttack2 = CROSSBOW_SecondaryAttack;
	self.weaponReload = CROSSBOW_Reload;
	self.weaponSelect = CROSSBOW_Select;
}

void CROSSBOW_Precache()
{
	precache_model(CROSSBOW_VIEW_MODEL);
	precache_model(CROSSBOW_WORLD_MODEL);
	precache_model(CROSSBOW_BOLT_MODEL);

	precache_sound(CROSSBOW_FIRE_SOUND);
	precache_sound(CROSSBOW_RELOAD_SOUND);
	precache_sound(CROSSBOW_HITBOD1_SOUND);
	precache_sound(CROSSBOW_HITBOD2_SOUND);
	precache_sound(CROSSBOW_HITWORLD_SOUND);
	precache_sound(CROSSBOW_FLY_SOUND);
}
