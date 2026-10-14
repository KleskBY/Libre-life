
//Settings
#define HANDGRENADE_FUSE			3.0		// total time from pin pull to explosion
#define HANDGRENADE_DAMAGE			Skill_GetValue("sk_plr_hand_grenade", 100)
#define HANDGRENADE_RADIUS			250
#define HANDGRENADE_VEL_MULTIPLIER	6.5
#define HANDGRENADE_VEL_MAX			1000
#define HANDGRENADE_THROW_DELAY		0.5		// cooldown between throws

//Models
#define HANDGRENADE_VIEW_MODEL		"models/v_grenade.iqm"
#define HANDGRENADE_WORLD_MODEL		"models/w_grenade.iqm"
#define HANDGRENADE_PROJ_MODEL		"models/w_grenade.iqm"

//Anims (matches Half-Life handgrenade_e enum)
#define HANDGRENADE_IDLE			0
#define HANDGRENADE_FIDGET			1
#define HANDGRENADE_PINPULL			2
#define HANDGRENADE_THROW1			3	// soft toss
#define HANDGRENADE_THROW2			4	// medium
#define HANDGRENADE_THROW3			5	// hard
#define HANDGRENADE_HOLSTER_ANIM	6
#define HANDGRENADE_DRAW			7

#define HANDGRENADE_AMMO ammoGrenades
.float handgrenade_pinTime;        // time pin was pulled (0 = not charging)
.float handgrenade_pickup;

//
// Grenade projectile entity (bouncy, fuse-timed)
//
void HandGrenade_Explode()
{
	Combat_Explode(HANDGRENADE_DAMAGE, HANDGRENADE_RADIUS);
}

void HandGrenade_BounceSound()
{
	Sound_Play(self, CHAN_VOICE, 0.25, ATTN_NORM, 100, "weapons/grenade_hit1.wav", "weapons/grenade_hit2.wav",
	                                  "weapons/grenade_hit3.wav");
}

void HandGrenade_Touch()
{
	if(other.takedamage) return;
	HandGrenade_BounceSound();
}

void HandGrenade_Create(entity creator, vector src, vector vel, float fuse)
{
	entity grenade = spawn();
	grenade.classname = "grenade";
	grenade.owner = creator;
	Player_ProjectileClip(grenade, creator);
	grenade.movetype = MOVETYPE_BOUNCE;
	grenade.solid = SOLID_BBOX;
	setmodel(grenade, HANDGRENADE_PROJ_MODEL);
	setsize(grenade, '-1 -1 -1', '1 1 1');
	setorigin(grenade, src);
	grenade.velocity = vel;
	grenade.angles = vectoangles(vel);
	grenade.avelocity = '300 200 0';
	grenade.scale = 0.5;
	grenade.bouncefactor = 0.3;
	grenade.think = HandGrenade_Explode;
	grenade.touch = HandGrenade_Touch;
	grenade.nextthink = time + fuse;
}


void HANDGRENADE_RetireOrSwitch()
{
	self.weapons = self.weapons & ~WEAPON_HANDGRENADE;
	self.impulse = WID_CROWBAR;
}

void HANDGRENADE_Throw()
{
	vector angThrow = self.v_angle + self.punchangle;
	if (angThrow_x < 0)
		angThrow_x = -10 + angThrow_x * ((90 - 10) / 90);
	else
		angThrow_x = -10 + angThrow_x * ((90 + 10) / 90);

	float flVel = (90 - angThrow_x) * HANDGRENADE_VEL_MULTIPLIER;
	if (flVel > HANDGRENADE_VEL_MAX) flVel = HANDGRENADE_VEL_MAX;

	makevectors(angThrow);
	vector src = self.origin + self.view_ofs + v_forward * 16;
	vector vel = v_forward * flVel + self.velocity;

	// Always explodes HANDGRENADE_FUSE seconds after the pin was pulled.
	float fuse = (self.handgrenade_pinTime + HANDGRENADE_FUSE) - time;
	if (fuse < 0) fuse = 0;

	HandGrenade_Create(self, src, vel, fuse);

	// Pick a throw anim by speed (matches HL THROW1/2/3).
	if (flVel < 500)         Weapon_SetFrame(HANDGRENADE_THROW1);
	else if (flVel < 1000)   Weapon_SetFrame(HANDGRENADE_THROW2);
	else                     Weapon_SetFrame(HANDGRENADE_THROW3);

	self.HANDGRENADE_AMMO = self.HANDGRENADE_AMMO - 1;
	self.currentammo = self.HANDGRENADE_AMMO;
	self.handgrenade_pinTime = 0;
	self.attack_finished = time + HANDGRENADE_THROW_DELAY;

	if (self.HANDGRENADE_AMMO <= 0)
	{
		self.think = HANDGRENADE_RetireOrSwitch;
		self.nextthink = time + HANDGRENADE_THROW_DELAY;
	}
	else
	{
		self.think = Player_Think;
		self.nextthink = time + HANDGRENADE_THROW_DELAY;
	}
}

void HANDGRENADE_ChargeThink()
{
	if (!self.handgrenade_pinTime) { Player_Think(); return; }

	if (!self.button0)
	{
		HANDGRENADE_Throw();
		return;
	}

	// Cook-off: holding past the fuse blows up in your hand.
	if (time >= self.handgrenade_pinTime + HANDGRENADE_FUSE)
	{
		// Spawn a zero-velocity grenade at the player's origin and let it explode immediately.
		makevectors(self.v_angle);
		vector src = self.origin + self.view_ofs;
		HandGrenade_Create(self, src, '0 0 0', 0);
		self.HANDGRENADE_AMMO = self.HANDGRENADE_AMMO - 1;
		self.currentammo = self.HANDGRENADE_AMMO;
		self.handgrenade_pinTime = 0;
		self.attack_finished = time + HANDGRENADE_THROW_DELAY;
		if (self.HANDGRENADE_AMMO <= 0)
		{
			self.think = HANDGRENADE_RetireOrSwitch;
			self.nextthink = time + HANDGRENADE_THROW_DELAY;
		}
		else
		{
			self.think = Player_Think;
			self.nextthink = time + HANDGRENADE_THROW_DELAY;
		}
		return;
	}

	self.think = HANDGRENADE_ChargeThink;
	self.nextthink = time + 0.05;
}

void HANDGRENADE_PrimaryAttack()
{
	// button is held; the per-frame think handles the release detection.
	if (self.handgrenade_pinTime) return;

	if (self.HANDGRENADE_AMMO <= 0) return;

	self.handgrenade_pinTime = time;
	Weapon_SetFrame(HANDGRENADE_PINPULL);
	self.attack_finished = time;
	self.think = HANDGRENADE_ChargeThink;
	self.nextthink = time + 0.05;
}

void HANDGRENADE_SecondaryAttack()
{
}

void HANDGRENADE_Reload()
{
}

void HANDGRENADE_Switch()
{
	self.handgrenade_pinTime = 0;        // never deploy mid-charge
	Weapon_SetFrame(HANDGRENADE_DRAW);
	self.reload = TRUE;
	self.think = Player_Think;
	self.nextthink = time + 0.5;
}

void HANDGRENADE_Select()
{
	if (!self.handgrenade_pickup)
		self.handgrenade_pickup = TRUE;

	self.currentClip = 0;
	self.currentammo = self.HANDGRENADE_AMMO;
	self.weaponmodel = HANDGRENADE_VIEW_MODEL;
	self.weaponSwitch = HANDGRENADE_Switch;
	self.weaponAttack = HANDGRENADE_PrimaryAttack;
	self.weaponAttack2 = HANDGRENADE_SecondaryAttack;
	self.weaponReload = HANDGRENADE_Reload;
	self.weaponSelect = HANDGRENADE_Select;
}

void HANDGRENADE_Precache()
{
	precache_model(HANDGRENADE_VIEW_MODEL);
	precache_model(HANDGRENADE_WORLD_MODEL);
	// precache_model(HANDGRENADE_PLAYER_MODEL);
	precache_model(HANDGRENADE_PROJ_MODEL);

	precache_sound("weapons/explode3.wav");
	precache_sound("weapons/grenade_hit1.wav");
	precache_sound("weapons/grenade_hit2.wav");
	precache_sound("weapons/grenade_hit3.wav");
	
}
