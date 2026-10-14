
//Settings
#define RPG_DAMAGE			Skill_GetValue("sk_plr_rpg", 120)
#define RPG_RADIUS			250
#define RPG_MAX_CLIP		1
#define RPG_MAX_CARRY		5
#define RPG_RATE			1.5
#define RPG_RELOAD_TIME		2.0
#define RPG_SOUND_RADIUS	3500

#define RPG_ROCKET_IGNITE_DELAY	0.1		// HL: rocket coasts before motor lights
#define RPG_ROCKET_INIT_VEL		250		// initial coast speed
#define RPG_ROCKET_MAX_VEL		1200	// after motor ignites (HL is 2000, tuned down)
#define RPG_ROCKET_GRAVITY		0.5
#define RPG_ROCKET_TRACK_TIME	1.2		// length of accel/homing phase
#define RPG_ROCKET_TRACK_ACCEL	200		// extra velocity per tick while homing
#define RPG_ROCKET_LIFETIME		6.0		// hard cap from HL FollowThink
#define RPG_ROCKET_COAST_MIN	900		// below this after ignition phase, detonate
#define RPG_ROCKET_THINK_RATE	0.1		// homing update interval

//Models
#define RPG_VIEW_MODEL		"models/v_rpg.iqm"
#define RPG_WORLD_MODEL		"models/w_rpg.iqm"
#define RPG_ROCKET_MODEL	"models/rpgrocket.iqm"

//Anims (matches Half-Life rpg_e enum)
#define RPG_IDLE			0
#define RPG_FIDGET			1
#define RPG_RELOAD_ANIM		2	// to reload
#define RPG_FIRE2			3	// to empty
#define RPG_HOLSTER1		4	// loaded
#define RPG_DRAW1			5	// loaded
#define RPG_HOLSTER2		6	// unloaded
#define RPG_DRAW_UL			7	// unloaded
#define RPG_IDLE_UL			8	// unloaded idle
#define RPG_FIDGET_UL		9	// unloaded fidget

//Sounds
#define RPG_FIRE_SOUND		"weapons/rocketfire1.wav"
#define RPG_IGNITE_SOUND	"weapons/rocket1.wav"
#define RPG_RELOAD_SOUND	"items/9mmclip1.wav"

#define RPG_AMMO ammoRockets
.float rpg_clip;
.float rpg_pickup;
.entity rpg_laser;
.float rocket_igniteTime;

void Rocket_Explode()
{
	Sound_Stop(self, CHAN_WEAPON);
	T_RadiusDamage(self, self.owner, RPG_DAMAGE, RPG_RADIUS, DMG_BLAST | DMG_ALWAYSGIB);
	te_explosion(self.origin);
	Sound_Play(self, CHAN_WEAPON, 1, Sound_Radius(RPG_SOUND_RADIUS), PITCH_NORM, "weapons/explode3.wav");
	remove(self);
}

void Rocket_Touch()
{
	if (other == self.owner) return;
	Rocket_Explode();
}

void Rocket_FollowThink();

void Rocket_IgniteThink()
{
	// Motor ignites: switch from coast to flying and hand off to the homing loop.
	self.movetype = MOVETYPE_FLY;
	self.effects |= EF_FULLBRIGHT;
	makevectors(self.angles);
	self.velocity = v_forward * RPG_ROCKET_MAX_VEL;
	Sound_Play(self, CHAN_WEAPON, 1, Sound_Radius(1200), PITCH_NORM, RPG_IGNITE_SOUND);
	pointparticles(particleeffectnum("TR_ROCKET"), self.origin, self.velocity, 1);
	self.rocket_igniteTime = time;
	self.think = Rocket_FollowThink;
	self.nextthink = time + RPG_ROCKET_THINK_RATE;
}

//
//
void Rocket_FollowThink()
{
	// Hard lifetime failsafe.
	if (time - self.rocket_igniteTime > RPG_ROCKET_LIFETIME)
	{
		Rocket_Explode();
		return;
	}

	float flSpeed = vlen(self.velocity);
	vector fwd;
	if (flSpeed > 0)
		fwd = self.velocity * (1 / flSpeed);
	else
	{
		makevectors([-self.angles_x, self.angles_y, 0]);	// angles come from vectoangles
		fwd = v_forward;
	}
	vector vecTarget = fwd;

	// Home on the player's laser spot if it's visible from the rocket.
	entity spot = self.owner.rpg_laser;
	if (spot && !wasfreed(spot) && !(spot.effects & EF_NODRAW))
	{
		traceline(self.origin, spot.origin, FALSE, self);
		if (trace_fraction >= 0.9)
		{
			vector vecDir = spot.origin - self.origin;
			float flDist = vlen(vecDir);
			if (flDist > 0)
			{
				vecDir = vecDir * (1 / flDist);
				float flDot = Math_DotProduct(fwd, vecDir);
				if ((flDot > 0) && (flDist * (1 - flDot) < 4096))
					vecTarget = vecDir;
			}
		}
	}

	if (time - self.rocket_igniteTime < RPG_ROCKET_TRACK_TIME)
	{
		// Homing + accel phase. Gentler blend than HL's 0.2/0.8 to keep the path smooth
		self.velocity = self.velocity * 0.6 + vecTarget * (flSpeed * 0.4 + RPG_ROCKET_TRACK_ACCEL);
		if (vlen(self.velocity) > RPG_ROCKET_MAX_VEL)
			self.velocity = normalize(self.velocity) * RPG_ROCKET_MAX_VEL;
	}
	else
	{
		self.velocity = self.velocity * 0.6 + vecTarget * flSpeed * 0.4;
		if (self.waterlevel == 0 && vlen(self.velocity) < RPG_ROCKET_COAST_MIN)
		{
			Rocket_Explode();
			return;
		}
	}

	// feedback into next tick's homing since we read velocity directly).
	if (vlen(self.velocity) > 0)
		self.angles = vectoangles(self.velocity);

	self.think = Rocket_FollowThink;
	self.nextthink = time + RPG_ROCKET_THINK_RATE;
}

void Rocket_Create(entity creator, vector src, vector ang)
{
	entity rocket = spawn();
	rocket.classname = "rpg_rocket";
	rocket.owner = creator;
	Player_ProjectileClip(rocket, creator);
	rocket.movetype = MOVETYPE_BOUNCE;
	rocket.solid = SOLID_BBOX;
	// rocket.gravity = RPG_ROCKET_GRAVITY;
	setmodel(rocket, RPG_ROCKET_MODEL);
	setsize(rocket, '-1 -1 -1', '1 1 1');
	setorigin(rocket, src);
	rocket.angles = ang;
	rocket.avelocity_z = 100;

	makevectors(ang);
	rocket.velocity = v_forward * RPG_ROCKET_INIT_VEL;
	rocket.modelflags = MF_ROCKET;
	rocket.touch = Rocket_Touch;
	rocket.think = Rocket_IgniteThink;
	rocket.nextthink = time + RPG_ROCKET_IGNITE_DELAY;
}

// RPG weapon
void RPG_ReloadFinish()
{
	Weapon_Reload(RPG_AMMO, rpg_clip, RPG_MAX_CLIP);
	self.think = Player_Think;
	self.nextthink = time + 0.1;
}

void RPG_Reload()
{
	self.currentClip = self.rpg_clip;
	if (self.rpg_clip >= RPG_MAX_CLIP) return;
	if (self.RPG_AMMO <= 0)
	{
		CycleWeaponReverseCommand();
		return;
	}

	Weapon_SetFrame(RPG_RELOAD_ANIM);
	self.nextthink = time + RPG_RELOAD_TIME;
	self.think = RPG_ReloadFinish;
	self.reload = TRUE;
	Sound_Play(self, CHAN_ITEM, 1, ATTN_NORM, PITCH_NORM, RPG_RELOAD_SOUND);
}

void RPG_FireRocket()
{
	if (self.rpg_clip <= 0)
	{
		self.attack_finished = time + 0.5;
		if (AUTORELOAD && self.RPG_AMMO > 0) self.impulse = 100;
		return;
	}

	self.rpg_clip = self.rpg_clip - 1;
	self.currentClip = self.rpg_clip;
	Weapon_SetFrame(RPG_FIRE2);

	makevectors(self.v_angle + self.punchangle);
	vector src = self.origin + self.view_ofs + v_forward * 16 + v_right * 8 - v_up * 8;
	Rocket_Create(self, src, self.v_angle);

	self.punchangle_x += random(-3, -1);
	Sound_Play(self, CHAN_WEAPON, 1, Sound_Radius(RPG_SOUND_RADIUS), PITCH_NORM, RPG_FIRE_SOUND);

	self.attack_finished = time + RPG_RATE;
	self.think = Player_Think;
	self.nextthink = time + RPG_RATE;

	if (AUTORELOAD && self.RPG_AMMO > 0) self.impulse = 100;
}

void RPG_PrimaryAttack()
{
	RPG_FireRocket();
}

void RPG_SecondaryAttack()
{
	if(self.rpg_laser && !wasfreed(self.rpg_laser))
	{
		remove(self.rpg_laser);
		self.rpg_laser = world;	// a freed edict gets reused, and rockets would home on it
	}
	else
	{
		self.rpg_laser = spawn();
		setmodel(self.rpg_laser, "sprites/laserdot.spr");
		self.rpg_laser.effects = EF_NODRAW;	// hidden until RPG_DrawLaser places it
	}
	self.attack_finished = time + 0.5;
}

void RPG_DrawLaser()
{
	if(!self.rpg_laser) return;
	if (wasfreed(self.rpg_laser)) return;
	if(self.weapon != WEAPON_RPG)
	{
		self.rpg_laser.effects = EF_NODRAW;
		// remove(self.rpg_laser);
		return;
	}
	makevectors(self.v_angle);
	vector src = self.origin + self.view_ofs;
	traceline(src, src + v_forward * 8192, FALSE, self);
	if ((trace_inopen && trace_inwater) || trace_fraction == 1)
	{
		self.rpg_laser.effects = EF_NODRAW;	// no surface to mark, so rockets stop homing
		return;
	}
	setorigin(self.rpg_laser, trace_endpos - v_forward);
	self.rpg_laser.effects = EF_ADDITIVE;
}

void RPG_Switch()
{
	Weapon_SetFrame(self.rpg_clip ? RPG_DRAW1 : RPG_DRAW_UL);
	self.reload = TRUE;
	self.think = Player_Think;
	self.nextthink = time + 0.5;
}

void RPG_Select()
{
	if (!self.rpg_pickup)
	{
		self.rpg_pickup = TRUE;
		self.rpg_clip = RPG_MAX_CLIP;
	}
	self.currentClip = self.rpg_clip;
	self.currentammo = self.RPG_AMMO;
	self.weaponmodel = RPG_VIEW_MODEL;
	self.weaponSwitch = RPG_Switch;
	self.weaponAttack = RPG_PrimaryAttack;
	self.weaponAttack2 = RPG_SecondaryAttack;
	self.weaponReload = RPG_Reload;
	self.weaponSelect = RPG_Select;
}

void RPG_Precache()
{
	precache_model(RPG_VIEW_MODEL);
	precache_model(RPG_WORLD_MODEL);
	// precache_model(RPG_PLAYER_MODEL);
	precache_model(RPG_ROCKET_MODEL);
	precache_model("sprites/laserdot.spr");

	precache_sound(RPG_FIRE_SOUND);
	precache_sound(RPG_IGNITE_SOUND);
	precache_sound(RPG_RELOAD_SOUND);
}
