
#define SNARK_FUSE_TIME			15
#define SNARK_HEALTH			Skill_GetValue("sk_snark_health", 2)
#define SNARK_DAMAGE_POP		Skill_GetValue("sk_snark_dmg_pop", 5)		// radius damage on detonate
#define SNARK_DAMAGE_BITE		Skill_GetValue("sk_snark_dmg_bite", 10)		// direct damage on ram
#define SNARK_RADIUS			120		// pop radius
#define SNARK_THROW_VEL			200
#define SNARK_HUNT_INTERVAL		2.0
#define SNARK_HUNT_RANGE		512
#define SNARK_BITE_COOLDOWN		0.5
#define SNARK_BOUNCE_COOLDOWN	0.1		// min time between SuperBounceTouch effects
#define SNARK_THROW_DELAY		0.3
#define SNARK_MAX_CARRY			10
#define SNARK_DEFAULT_GIVE		5
#define SNARK_SOUND_RADIUS		800

//Models
#define SNARK_VIEW_MODEL		"models/v_squeak.iqm"
#define SNARK_WORLD_MODEL		"models/w_sqknest.iqm"	// inventory nest
#define SNARK_PROJ_MODEL		"models/w_squeak.iqm"	// live snark

//Anims
#define SQUEAK_IDLE1			0
#define SQUEAK_FIDGETFIT		1
#define SQUEAK_FIDGETNIP		2
#define SQUEAK_DOWN				3
#define SQUEAK_UP				4
#define SQUEAK_THROW			5

//Sounds
#define SNARK_BLAST_SOUND		"squeek/sqk_blast1.wav"
#define SNARK_DIE_SOUND			"squeek/sqk_die1.wav"
#define SNARK_HUNT1_SOUND		"squeek/sqk_hunt1.wav"
#define SNARK_HUNT2_SOUND		"squeek/sqk_hunt2.wav"
#define SNARK_HUNT3_SOUND		"squeek/sqk_hunt3.wav"
#define SNARK_DEPLOY_SOUND		"squeek/sqk_deploy1.wav"
#define SNARK_BODYSPLAT_SOUND	"common/bodysplat.wav"

#define SNARK_AMMO ammoSnarks
.float snark_pickup;

.float snark_die;				// time at which the snark auto-pops
.float snark_nextHunt;			// next time we run the hunt step
.float snark_nextBounce;		// next time bounce SFX can play
.float snark_nextBite;			// next time a bite can deal damage

float Snark_PitchForTime()
{
	float remaining = self.snark_die - time;
	if (remaining < 0) remaining = 0;
	float pitch = 155 - 60 * (remaining / SNARK_FUSE_TIME);
	if (pitch < 80) pitch = 80;
	if (pitch > 155) pitch = 155;
	return pitch;
}

//
//
vector Snark_TargetPoint(entity targ)
{
	vector targetPos = (targ.absmin + targ.absmax) * 0.5;
	float targ_h = targ.absmax_z - targ.absmin_z;
	float bandMin;
	float bandMax;

	if (self.origin_x < targ.absmin_x) targetPos_x = targ.absmin_x;
	else if (self.origin_x > targ.absmax_x) targetPos_x = targ.absmax_x;
	else targetPos_x = self.origin_x;

	if (self.origin_y < targ.absmin_y) targetPos_y = targ.absmin_y;
	else if (self.origin_y > targ.absmax_y) targetPos_y = targ.absmax_y;
	else targetPos_y = self.origin_y;

	if (targ_h < 16) targ_h = 16;
	bandMin = targ.absmin_z + targ_h * 0.25;
	bandMax = targ.absmin_z + targ_h * 0.65;

	targetPos_z = self.origin_z;
	if (targetPos_z < bandMin) targetPos_z = bandMin;
	if (targetPos_z > bandMax) targetPos_z = bandMax;

	return targetPos;
}

void Snark_ApplyBounceVelocity(entity targ)
{
	if (targ)
	{
		vector lateralVel = self.velocity;
		vector targetPos = Snark_TargetPoint(targ);
		vector toTarget = targetPos - self.origin;

		lateralVel_z = 0;
		toTarget_z = 0;

		// Keep the hop looking alive: vary the aim point a bit without losing
		// the hull-aware targeting.
		float jitterXY = vlen(targ.absmax - targ.absmin) * 0.08;
		if (jitterXY < 4) jitterXY = 4;
		if (jitterXY > 12) jitterXY = 12;
		float jitterZ = (targ.absmax_z - targ.absmin_z) * 0.1;
		if (jitterZ < 4) jitterZ = 4;
		if (jitterZ > 10) jitterZ = 10;

		targetPos_x = targetPos_x + random(-jitterXY, jitterXY);
		targetPos_y = targetPos_y + random(-jitterXY, jitterXY);
		targetPos_z = targetPos_z + random(-jitterZ, jitterZ);
		toTarget = targetPos - self.origin;
		toTarget_z = 0;

		float speedXY = vlen(lateralVel);
		if (speedXY < 140) speedXY = 140;
		if (speedXY > 360) speedXY = 360;

		float distXY = vlen(toTarget);
		if (distXY < 24) distXY = 24;

		float flytime = distXY / speedXY;
		flytime = flytime * random(0.92, 1.08);
		if (flytime < 0.12) flytime = 0.12;
		if (flytime > 0.45) flytime = 0.45;

		float targetHeight = targetPos_z - self.origin_z;
		self.velocity_z = (targetHeight + cvar("sv_gravity") * flytime * flytime) / flytime;
		self.velocity_z = self.velocity_z + random(-12, 18);

		if (self.velocity_z < 160) self.velocity_z = 160;
		if (self.velocity_z > 340) self.velocity_z = 340;
	}
	else
	{
		self.velocity_z = 220;
	}
}

void Snark_Detonate()
{
	Sound_Play(self, CHAN_ITEM, 1, Sound_Radius(SNARK_SOUND_RADIUS), PITCH_NORM, SNARK_BLAST_SOUND);
	Sound_Play(self, CHAN_VOICE, 0.75, ATTN_NORM, PITCH_NORM, SNARK_BODYSPLAT_SOUND);
	te_wizspike(self.origin);

	self.model = "";
	self.modelindex = 0;
	self.solid = SOLID_NOT;
	self.takedamage = DAMAGE_NO;
	self.touch = SUB_Null;
	self.think = SUB_Remove;
	self.nextthink = time + 0.2;
	
	entity attacker = self.owner;
	if (!attacker) attacker = self;
	if (self.dmg < SNARK_DAMAGE_POP) self.dmg = SNARK_DAMAGE_POP;
	T_RadiusDamage(self, attacker, self.dmg, SNARK_RADIUS, DMG_BLAST);
}

// anything, not just stuff in front of it.
entity Snark_FindTarget()
{
	entity best = world;
	float  bestDist = SNARK_HUNT_RANGE;

	entity e = findradius(self.origin, SNARK_HUNT_RANGE);
	while (e)
	{
		if (e != self && e != self.owner && e.takedamage && e.health > 0 && e.classname != "monster_snark")
		{
			float d = vlen(e.origin - self.origin);
			if (d < bestDist)
			{
				traceline(self.origin, e.origin, TRUE, self);	// MOVE_NOMONSTERS
				if (trace_fraction >= 0.9 || trace_ent == e)
				{
					best = e;
					bestDist = d;
				}
			}
		}
		e = e.chain;
	}
	return best;
}

void Snark_HuntThink()
{
	if (time >= self.snark_die - 10) self.owner = world;
	if (time >= self.snark_die)
	{
		Snark_Detonate();
		return;
	}

	// Death-rattle squeak in the last 0.5s-0.3s window.
	float t = self.snark_die - time;
	if (t <= 0.5 && t >= 0.3)
	{
		Sound_Play(self, CHAN_VOICE, 1, Sound_Radius(SNARK_SOUND_RADIUS), PITCH_NORM, SNARK_DIE_SOUND);
	}

	// sink forever, mirroring HL's velocity.z += 8 float hack.
	if (self.waterlevel >= 2)
	{
		if (self.movetype == MOVETYPE_STEP) self.movetype = MOVETYPE_FLY;
		self.velocity = self.velocity * 0.9;
		self.velocity_z = self.velocity_z + 8;
	}
	else if (self.movetype == MOVETYPE_FLY)
	{
		self.movetype = MOVETYPE_STEP;
	}

	self.nextthink = time + 0.1;
	self.think = Snark_HuntThink;

	if (self.snark_nextHunt > time) return;
	self.snark_nextHunt = time + SNARK_HUNT_INTERVAL;

	entity targ = Snark_FindTarget();
	if (targ)
	{
		vector dir = normalize(Snark_TargetPoint(targ) - self.origin);
		dir_z = 0;
		if (dir != '0 0 0') dir = normalize(dir);
		
		float flVel = vlen(self.velocity);
		float flAdj = 50 / (flVel + 10);
		if (flAdj > 1.2) flAdj = 1.2;
		self.velocity = self.velocity * flAdj + dir * 300; // Blend: keep existing momentum a bit, bias hard toward target.
	}
	
	// Bounce off the floor using the target hull and current lateral speed
	// instead of a random vertical kick.
	if (self.flags & FL_ONGROUND) 
	{
		self.flags = self.flags - FL_ONGROUND;
		setorigin(self, self.origin + '0 0 1');
		Snark_ApplyBounceVelocity(targ);
	}

	// Spin while airborne; settle spin on ground.
	if (self.flags & FL_ONGROUND) self.avelocity = '0 0 0';
	else if (self.avelocity == '0 0 0')
	{
		self.avelocity_x = random(-100, 100);
		self.avelocity_z = random(-100, 100);
	}

	self.angles = vectoangles(self.velocity);
	self.angles_x = 0;
	self.angles_z = 0;
}

// Touch handler: bounce sfx + optional bite if we hit something damageable.
void Snark_BounceTouch()
{
	// Stop colliding with the thrower once we've left their hull.
	if (self.owner && other == self.owner) return;
	self.owner = self.owner;	// keep owner for damage attribution

	self.angles_x = 0;
	self.angles_z = 0;

	// Throttle touches so we don't play bounce sfx every physics tick
	// when sliding along a wall.
	if (self.snark_nextBounce > time) return;
	self.snark_nextBounce = time + SNARK_BOUNCE_COOLDOWN;

	float pitch = Snark_PitchForTime();

	// Bite: if the thing we hit is damageable and the bite cooldown has
	// elapsed, tear a chunk off and play the deploy chirp.
	if (other.takedamage && self.snark_nextBite < time && other.classname != "monster_snark" && !(other.flags & FL_WORLDBRUSH))
	{
		T_Damage(other, self, self.owner, SNARK_DAMAGE_BITE, DMG_SLASH);
		Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, SNARK_DEPLOY_SOUND);
		self.snark_nextBite = time + SNARK_BITE_COOLDOWN;

		// more carnage when the timer runs out. HL doubles down this way.
		self.dmg = self.dmg + SNARK_DAMAGE_POP;
	}

	// Resume hunting immediately after a collision, overriding the 2s gap.
	self.snark_nextHunt = time;
	if (!(self.flags & FL_ONGROUND))
	{
		Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM,
			SNARK_HUNT1_SOUND, SNARK_HUNT2_SOUND, SNARK_HUNT3_SOUND);
	}
}


// Spawn a live snark at `src`, thrown by `creator` with initial velocity `vel`.
void Snark_Create(entity creator, vector src, vector vel)
{
	entity s = spawn();
	s.classname = "monster_snark";
	s.owner = creator;
	Player_ProjectileClip(s, creator);
	s.movetype = MOVETYPE_STEP;
	s.solid = SOLID_SLIDEBOX;
	s.takedamage = DAMAGE_AIM;
	s.health = SNARK_HEALTH;
	s.flags = s.flags | FL_MONSTER;
	setmodel(s, SNARK_PROJ_MODEL);
	setsize(s, '-1 -1 -1', '1 1 1');
	setorigin(s, src);
	s.velocity = vel;
	s.angles = vectoangles(vel);
	s.avelocity = '0 100 0';		// starts spinning so it looks alive

	s.dmg = SNARK_DAMAGE_POP;		// base pop damage; bites add more (HL parity)
	s.snark_die = time + SNARK_FUSE_TIME;
	s.snark_nextHunt = time + 1;
	s.snark_nextBounce = 0;
	s.snark_nextBite = 0;

	s.touch = Snark_BounceTouch;
	s.think = Snark_HuntThink;
	s.nextthink = time + 0.1;
	s.th_die  = Snark_Detonate;
}

void SNARK_RetireOrSwitch()
{
	self.weapons = self.weapons & ~WEAPON_SNARK;
	self.impulse = WID_CROWBAR;
}

void SNARK_Throw()
{
	if (self.SNARK_AMMO <= 0) return;

	makevectors(self.v_angle + self.punchangle);
	vector src = self.origin + self.view_ofs + v_forward * 24;
	vector vel = v_forward * SNARK_THROW_VEL + self.velocity;

	Snark_Create(self, src, vel);

	Weapon_SetFrame(SQUEAK_THROW);
	self.SNARK_AMMO = self.SNARK_AMMO - 1;
	self.currentammo = self.SNARK_AMMO;

	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100, SNARK_HUNT2_SOUND, SNARK_HUNT3_SOUND);

	self.attack_finished = time + SNARK_THROW_DELAY;

	if (self.SNARK_AMMO <= 0)
	{
		self.think = SNARK_RetireOrSwitch;
		self.nextthink = time + SNARK_THROW_DELAY;
	}
	else
	{
		self.think = Player_Think;
		self.nextthink = time + SNARK_THROW_DELAY;
	}
}

void SNARK_PrimaryAttack()   { SNARK_Throw(); }
void SNARK_SecondaryAttack() { }

void SNARK_Reload() { }

void SNARK_Switch()
{
	Weapon_SetFrame(SQUEAK_UP);
	self.reload = TRUE;

	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100, SNARK_HUNT2_SOUND, SNARK_HUNT3_SOUND);

	self.think = Player_Think;
	self.nextthink = time + 0.5;
}

void SNARK_Select()
{
	if (!self.snark_pickup) self.snark_pickup = TRUE;

	self.currentClip = 0;
	self.currentammo = self.SNARK_AMMO;
	self.weaponmodel = SNARK_VIEW_MODEL;
	self.weaponSwitch  = SNARK_Switch;
	self.weaponAttack  = SNARK_PrimaryAttack;
	self.weaponAttack2 = SNARK_SecondaryAttack;
	self.weaponReload  = SNARK_Reload;
	self.weaponSelect  = SNARK_Select;
}

void SNARK_Precache()
{
	precache_model(SNARK_VIEW_MODEL);
	precache_model(SNARK_WORLD_MODEL);
	// precache_model(SNARK_PLAYER_MODEL);
	precache_model(SNARK_PROJ_MODEL);

	precache_sound(SNARK_BLAST_SOUND);
	precache_sound(SNARK_DIE_SOUND);
	precache_sound(SNARK_HUNT1_SOUND);
	precache_sound(SNARK_HUNT2_SOUND);
	precache_sound(SNARK_HUNT3_SOUND);
	precache_sound(SNARK_DEPLOY_SOUND);
	precache_sound(SNARK_BODYSPLAT_SOUND);
}
