
//Settings
#define SATCHEL_DAMAGE			Skill_GetValue("sk_plr_satchel", 150)
#define SATCHEL_RADIUS			250
#define SATCHEL_MAX_CARRY		5
#define SATCHEL_THROW_VEL		274		// HL Throw() forward speed
#define SATCHEL_THROW_DELAY		1.0
#define SATCHEL_DETONATE_DELAY	0.5

// m_chargeReady states
#define SATCHEL_MODE_THROW		0		// holding charges, no deployed ones
#define SATCHEL_MODE_RADIO		1		// at least one deployed, detonator in hand
#define SATCHEL_MODE_JUSTFIRED	2		// just detonated, transition back next frame

//Models
#define SATCHEL_VIEW_MODEL			"models/v_satchel.iqm"
#define SATCHEL_VIEW_RADIO_MODEL	"models/v_satchel_radio.iqm"
#define SATCHEL_WORLD_MODEL			"models/w_satchel.iqm"
#define SATCHEL_CHARGE_MODEL		"models/w_satchel.iqm"

//Anims (matches Half-Life satchel_e / satchel_radio_e)
#define SATCHEL_IDLE1			0
#define SATCHEL_FIDGET1			1
#define SATCHEL_DRAW			2
#define SATCHEL_DROP			3

#define SATCHEL_RADIO_IDLE1		0
#define SATCHEL_RADIO_FIDGET1	1
#define SATCHEL_RADIO_DRAW		2
#define SATCHEL_RADIO_FIRE		3
#define SATCHEL_RADIO_HOLSTER	4

//Sounds
#define SATCHEL_BOUNCE1_SOUND	"weapons/g_bounce1.wav"
#define SATCHEL_BOUNCE2_SOUND	"weapons/g_bounce2.wav"
#define SATCHEL_BOUNCE3_SOUND	"weapons/g_bounce3.wav"

#define SATCHEL_AMMO ammoSatchels
.float satchel_ready;
.float satchel_pickup;

//
// Satchel charge projectile entity
//
void Satchel_BounceSound()
{
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100, SATCHEL_BOUNCE1_SOUND, SATCHEL_BOUNCE2_SOUND, SATCHEL_BOUNCE3_SOUND);
}

void Satchel_Explode()
{
	T_RadiusDamage(self, self.owner, SATCHEL_DAMAGE, SATCHEL_RADIUS, DMG_BLAST | DMG_ALWAYSGIB);
	te_explosion(self.origin);
	Sound_Play(self, CHAN_WEAPON, 1, Sound_Radius(3500), PITCH_NORM, "weapons/explode3.wav");
	remove(self);
}

void Satchel_Slide()
{
	// Don't detonate on the guy who threw it.
	if (other == self.owner) return;

	traceline(self.origin, self.origin - '0 0 10', TRUE, self);
	if (trace_fraction < 1.0)
	{
		self.velocity  = self.velocity  * 0.95;
		self.avelocity = self.avelocity * 0.9;
	}

	// Play a bounce sound if we weren't on the ground and were moving fast enough.
	if (!(self.flags & FL_ONGROUND))
	{
		vector v2d = self.velocity;
		v2d_z = 0;
		if (vlen(v2d) > 10) Satchel_BounceSound();
	}
}

void Satchel_Think()
{
	self.nextthink = time + 0.1;

	// Water behavior: float up, drift, slower avelocity.
	if (self.waterlevel == 3)
	{
		self.movetype  = MOVETYPE_FLY;
		self.velocity  = self.velocity * 0.8;
		self.avelocity = self.avelocity * 0.9;
		self.velocity_z = self.velocity_z + 8;
	}
	else if (self.waterlevel == 0)
	{
		self.movetype = MOVETYPE_BOUNCE;
	}
	else
	{
		self.velocity_z = self.velocity_z - 8;
	}
}

void Satchel_Create(entity creator, vector src, vector vel)
{
	entity charge = spawn();
	charge.classname = "monster_satchel";
	charge.owner = creator;
	Player_ProjectileClip(charge, creator);
	charge.movetype = MOVETYPE_BOUNCE;
	charge.solid = SOLID_BBOX;
	// charge.gravity = 0.5;
	setmodel(charge, SATCHEL_CHARGE_MODEL);
	setsize(charge, '-1 -1 -1', '1  1 1');
	setorigin(charge, src);
	charge.angles = '270 180 90';
	charge.velocity = vel;
	charge.avelocity = '0 400 0';
	charge.touch = Satchel_Slide;
	charge.think = Satchel_Think;
	charge.nextthink = time + 0.1;
}

//
// Walk the entity list and detonate every charge owned by `owner`.
// Called by the radio detonator on secondary fire.
//
void Satchel_DetonateAll(entity creator)
{
	entity e = find(world, classname, "monster_satchel");
	while(e)
	{
		if (e.owner == creator)
		{
			entity oself = self;
			self = e;
			Satchel_Explode();
			self = oself;
		}
		e = find(e, classname, "monster_satchel");
	}
}

// Returns TRUE if the player has at least one live satchel in the world.
float Satchel_HasLive(entity creator)
{
	entity e = find(world, classname, "monster_satchel");
	while(e)
	{
		if (e.owner == creator)
		{
			return TRUE;
		}
		e = find(e, classname, "monster_satchel");
	}
	return FALSE;
}

void SATCHEL_Throw()
{
	if (self.SATCHEL_AMMO <= 0) return;

	makevectors(self.v_angle + self.punchangle);
	vector src = self.origin + self.view_ofs + v_forward * 16;
	vector vel = v_forward * SATCHEL_THROW_VEL + self.velocity;

	Satchel_Create(self, src, vel);

	// Switch to radio mode now that we have at least one deployed.
	self.satchel_ready = SATCHEL_MODE_RADIO;
	self.weaponmodel = SATCHEL_VIEW_RADIO_MODEL;
	Weapon_SetFrame(SATCHEL_RADIO_DRAW);

	self.SATCHEL_AMMO = self.SATCHEL_AMMO - 1;
	self.currentammo = self.SATCHEL_AMMO;
	self.attack_finished = time + SATCHEL_THROW_DELAY;
	self.think = Player_Think;
	self.nextthink = time + SATCHEL_THROW_DELAY;
}

void SATCHEL_PrimaryAttack()
{
	if (self.satchel_ready == SATCHEL_MODE_JUSTFIRED) return;
	if (time < self.attack_finished) return;
	SATCHEL_Throw();
}

void SATCHEL_RetireOrSwitch()
{
	self.weapons = self.weapons & ~WEAPON_SATCHEL;
	self.satchel_ready = SATCHEL_MODE_THROW;
	self.impulse = WID_CROWBAR;
}

void SATCHEL_PostDetonate()
{
	// Called after the SATCHEL_DETONATE_DELAY transition.
	if (self.SATCHEL_AMMO > 0)
	{
		self.satchel_ready = SATCHEL_MODE_THROW;
		self.weaponmodel = SATCHEL_VIEW_MODEL;
		Weapon_SetFrame(SATCHEL_DRAW);
		self.think = Player_Think;
		self.nextthink = time + 0.1;
	}
	else
	{
		SATCHEL_RetireOrSwitch();
	}
}

void SATCHEL_SecondaryAttack()
{
	// Only meaningful in radio mode with at least one deployed charge.
	if (self.satchel_ready != SATCHEL_MODE_RADIO) return;
	if (time < self.attack_finished) return;
	if (!Satchel_HasLive(self)) return;

	Satchel_DetonateAll(self);

	self.satchel_ready = SATCHEL_MODE_JUSTFIRED;
	Weapon_SetFrame(SATCHEL_RADIO_FIRE);
	self.attack_finished = time + SATCHEL_DETONATE_DELAY;
	self.think = SATCHEL_PostDetonate;
	self.nextthink = time + SATCHEL_DETONATE_DELAY;
}

void SATCHEL_Reload()
{
}

void SATCHEL_Switch()
{
	if (self.satchel_ready == SATCHEL_MODE_RADIO)
	{
		self.weaponmodel = SATCHEL_VIEW_RADIO_MODEL;
		Weapon_SetFrame(SATCHEL_RADIO_DRAW);
	}
	else
	{
		self.weaponmodel = SATCHEL_VIEW_MODEL;
		Weapon_SetFrame(SATCHEL_DRAW);
	}
	self.reload = TRUE;
	self.think = Player_Think;
	self.nextthink = time + 0.5;
}

void SATCHEL_Select()
{
	if (!self.satchel_pickup) self.satchel_pickup = TRUE;

	// If all live satchels have been cleared (e.g. map change, death) and the
	// weapon still thinks it's in radio mode, snap back to throw mode.
	if (self.satchel_ready == SATCHEL_MODE_RADIO && !Satchel_HasLive(self))
		self.satchel_ready = SATCHEL_MODE_THROW;

	self.currentClip = 0;
	self.currentammo = self.SATCHEL_AMMO;

	if (self.satchel_ready == SATCHEL_MODE_RADIO)
		self.weaponmodel = SATCHEL_VIEW_RADIO_MODEL;
	else
		self.weaponmodel = SATCHEL_VIEW_MODEL;

	self.weaponSwitch = SATCHEL_Switch;
	self.weaponAttack = SATCHEL_PrimaryAttack;
	self.weaponAttack2 = SATCHEL_SecondaryAttack;
	self.weaponReload = SATCHEL_Reload;
	self.weaponSelect = SATCHEL_Select;
}

void SATCHEL_Precache()
{
	precache_model(SATCHEL_VIEW_MODEL);
	precache_model(SATCHEL_VIEW_RADIO_MODEL);
	precache_model(SATCHEL_WORLD_MODEL);
	precache_model(SATCHEL_CHARGE_MODEL);

	precache_sound(SATCHEL_BOUNCE1_SOUND);
	precache_sound(SATCHEL_BOUNCE2_SOUND);
	precache_sound(SATCHEL_BOUNCE3_SOUND);
}
