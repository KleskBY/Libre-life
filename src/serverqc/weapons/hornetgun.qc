
//Settings
#define HGUN_DAMAGE				Skill_GetValue("sk_plr_hornet", 7)
#define HGUN_MAX_CARRY			8
#define HGUN_DEFAULT_GIVE		8
#define HGUN_RECHARGE_SP		0.5
#define HGUN_RECHARGE_MP		0.3
#define HGUN_RATE_TRACK			0.25	// primary cooldown (HL getNextAttackDelay 0.25)
#define HGUN_RATE_FAST			0.1		// secondary cooldown
#define HGUN_SOUND_RADIUS		1200

#define HORNET_TYPE_RED			0		// tracking hornet
#define HORNET_TYPE_ORANGE		1		// fast dart hornet
#define HORNET_RED_SPEED		600
#define HORNET_ORANGE_SPEED		800
#define HORNET_TRACK_VEL		300		// primary launch velocity
#define HORNET_DART_VEL			1200	// secondary launch velocity
#define HORNET_TRACK_LIFE_SP	5.0
#define HORNET_TRACK_LIFE_MP	3.5
#define HORNET_DART_LIFE		4.0
#define HORNET_SEARCH_RADIUS	1024
#define HORNET_SEARCH_CONE		0.5		// dot( fwd, toTarget ) gate
#define HORNET_BUZZ_VOLUME		0.8

//Models
#define HGUN_VIEW_MODEL			"models/v_hgun.iqm"
#define HGUN_WORLD_MODEL		"models/w_hgun.iqm"
#define HORNET_MODEL			"models/hornet.iqm"

//Anims (matches Half-Life hgun_e enum)
#define HGUN_IDLE1			0
#define HGUN_FIDGETSWAY		1
#define HGUN_FIDGETSHAKE	2
#define HGUN_DOWN			3
#define HGUN_UP				4
#define HGUN_SHOOT			5

//Sounds
#define HGUN_FIRE1_SOUND		"agrunt/ag_fire1.wav"
#define HGUN_FIRE2_SOUND		"agrunt/ag_fire2.wav"
#define HGUN_FIRE3_SOUND		"agrunt/ag_fire3.wav"
#define HORNET_BUZZ1_SOUND		"hornet/ag_buzz1.wav"
#define HORNET_BUZZ2_SOUND		"hornet/ag_buzz2.wav"
#define HORNET_BUZZ3_SOUND		"hornet/ag_buzz3.wav"
#define HORNET_HIT1_SOUND		"hornet/ag_hornethit1.wav"
#define HORNET_HIT2_SOUND		"hornet/ag_hornethit2.wav"
#define HORNET_HIT3_SOUND		"hornet/ag_hornethit3.wav"

#define HGUN_AMMO ammoHornets
.float hgun_pickup;
.float hgun_rechargeTime;	// next time ammo auto-replenishes by 1
.float hgun_firePhase;		// 0..7 muzzle-offset cycle for secondary

// Hornet projectile fields
.float hornet_type;
.float hornet_flySpeed;
.float hornet_stopAttack;	// time at which the hornet gives up and removes itself

//
// Hornet projectile
//
void Hornet_Remove()
{
	remove(self);
}

void Hornet_DieTouch()
{
	if (other && other.takedamage)
	{
		Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM,
			HORNET_HIT1_SOUND, HORNET_HIT2_SOUND, HORNET_HIT3_SOUND);

		T_Damage(other, self, self.owner, HGUN_DAMAGE, DMG_BULLET | DMG_NEVERGIB);
	}

	self.model = "";			// stop drawing
	self.modelindex = 0;
	self.solid = SOLID_NOT;
	self.touch = SUB_Null;
	self.think = Hornet_Remove;
	self.nextthink = time + 0.5;
}

void Hornet_DartTouch()
{
	// is a straight line so we don't want to self-destruct on our muzzle.
	if (other == self.owner) return;
	if (other.classname == "hornet") return;
	Hornet_DieTouch();
}

void Hornet_TrackTouch()
{
	if (other == self.owner || other.classname == "hornet")
	{
		self.solid = SOLID_NOT;
		return;
	}

	if (other.takedamage == 0 && other.classname != "player")
	{
		// detonate, matching HL's "turn around" behavior for friendly targets.
		vector v = normalize(self.velocity);
		v_x = -v_x;
		v_y = -v_y;
		setorigin(self, self.origin + v * 4);
		self.velocity = v * self.hornet_flySpeed;
		return;
	}

	Hornet_DieTouch();
}

//
//
entity Hornet_FindTarget()
{
	entity best = world;
	float  bestDist = HORNET_SEARCH_RADIUS;

	vector fwd;
	if (vlen(self.velocity) > 0.1) fwd = normalize(self.velocity);
	else { makevectors(self.angles); fwd = v_forward; }

	entity e = findradius(self.origin, HORNET_SEARCH_RADIUS);
	while (e)
	{
		if (e != self && e != self.owner && e.takedamage && e.health > 0
			&& e.classname != "hornet")
		{
			vector to = e.origin - self.origin;
			float d = vlen(to);
			if (d > 0 && d < bestDist)
			{
				vector toN = to * (1 / d);
				if (Math_DotProduct(fwd, toN) >= HORNET_SEARCH_CONE)
				{
					traceline(self.origin, e.origin, TRUE, self);	// MOVE_NOMONSTERS
					if (trace_fraction >= 0.9 || trace_ent == e)
					{
						best = e;
						bestDist = d;
					}
				}
			}
		}
		e = e.chain;
	}
	return best;
}

void Hornet_TrackTarget()
{
	if (time > self.hornet_stopAttack)
	{
		self.touch = SUB_Null;
		self.think = Hornet_Remove;
		self.nextthink = time + 0.1;
		return;
	}

	entity targ = Hornet_FindTarget();

	vector flightDir;
	if (vlen(self.velocity) < 0.1) { makevectors(self.angles); flightDir = v_forward; }
	else flightDir = normalize(self.velocity);

	vector dirToEnemy;
	if (targ != world) dirToEnemy = normalize(targ.origin - self.origin);
	else dirToEnemy = flightDir;

	float delta = Math_DotProduct(flightDir, dirToEnemy);

	if (targ != world && delta < 0.5)
	{
		Sound_Play(self, CHAN_VOICE, HORNET_BUZZ_VOLUME, ATTN_NORM, PITCH_NORM,
			HORNET_BUZZ1_SOUND, HORNET_BUZZ2_SOUND, HORNET_BUZZ3_SOUND);
	}

	if (delta <= 0 && self.hornet_type == HORNET_TYPE_RED) delta = 0.25;

	vector blended = normalize(flightDir + dirToEnemy);

	if (self.hornet_type == HORNET_TYPE_RED)
	{
		self.velocity = blended * (self.hornet_flySpeed * delta);
		self.nextthink = time + random(0.1, 0.3);
	}
	else
	{
		// Orange variant holds constant speed through turns.
		self.velocity = blended * self.hornet_flySpeed;
		self.nextthink = time + 0.1;
	}

	self.angles = vectoangles(self.velocity);
}

//
//
void Hornet_IgniteTrail()
{
	if (self.hornet_type == HORNET_TYPE_RED) self.modelflags = MF_TRACER2;
	else                                     self.modelflags = MF_TRACER3;
	self.modelflags = MF_TRACER2;
	self.effects |= EF_ADDITIVE;
}

void Hornet_StartTrack()
{
	Hornet_IgniteTrail();
	self.touch = Hornet_TrackTouch;
	self.think = Hornet_TrackTarget;
	self.nextthink = time + 0.1;
}

void Hornet_StartDart()
{
	Hornet_IgniteTrail();
	self.touch = Hornet_DartTouch;
	self.think = Hornet_Remove;
	self.nextthink = time + HORNET_DART_LIFE;
}

//
// Constructs a hornet entity at `src` facing `ang`, belonging to `creator`.
// Caller decides whether to then call Hornet_StartTrack or Hornet_StartDart.
//
entity Hornet_Create(entity creator, vector src, vector ang)
{
	entity h = spawn();
	h.classname = "hornet";
	h.owner = creator;
	Player_ProjectileClip(h, creator);
	h.movetype = MOVETYPE_FLY;
	h.solid = SOLID_BBOX;
	h.takedamage = DAMAGE_NO;
	h.health = 1;
	setmodel(h, HORNET_MODEL);
	setsize(h, '-1 -1 -1', '1 1 1');
	setorigin(h, src);
	h.angles = ang;

	if (Math_RandomInt(1, 5) <= 2)
	{
		h.hornet_type = HORNET_TYPE_RED;
		h.hornet_flySpeed = HORNET_RED_SPEED;
	}
	else
	{
		h.hornet_type = HORNET_TYPE_ORANGE;
		h.hornet_flySpeed = HORNET_ORANGE_SPEED;
	}

	if (IsMultiplayer()) h.hornet_stopAttack = time + HORNET_TRACK_LIFE_MP;
	else                 h.hornet_stopAttack = time + HORNET_TRACK_LIFE_SP;

	return h;
}

//
// Hornet Gun weapon
//
float HGUN_RechargeTime()
{
	if (IsMultiplayer()) return HGUN_RECHARGE_MP;
	return HGUN_RECHARGE_SP;
}

void HGUN_Reload()
{
	if (self.HGUN_AMMO >= HGUN_MAX_CARRY) return;
	while (self.HGUN_AMMO < HGUN_MAX_CARRY && self.hgun_rechargeTime < time)
	{
		self.HGUN_AMMO = self.HGUN_AMMO + 1;
		self.hgun_rechargeTime = self.hgun_rechargeTime + HGUN_RechargeTime();
	}
	self.currentammo = self.HGUN_AMMO;
}

void HGUN_FireTrack()
{
	HGUN_Reload();
	if (self.HGUN_AMMO <= 0) return;

	makevectors(self.v_angle + self.punchangle);
	vector src = self.origin + self.view_ofs + v_forward * 16 + v_right * 8 - v_up * 12;
	vector ang = self.v_angle;

	entity h = Hornet_Create(self, src, ang);
	h.velocity = v_forward * HORNET_TRACK_VEL;
	h.angles = vectoangles(h.velocity);

	entity oself = self;
	self = h;
	Hornet_StartTrack();
	self = oself;

	self.hgun_rechargeTime = time + HGUN_RechargeTime();
	self.HGUN_AMMO = self.HGUN_AMMO - 1;
	self.currentammo = self.HGUN_AMMO;

	Weapon_SetFrame(HGUN_SHOOT);

	Sound_Play(self, CHAN_WEAPON, 1, Sound_Radius(HGUN_SOUND_RADIUS), PITCH_NORM,
		HGUN_FIRE1_SOUND, HGUN_FIRE2_SOUND, HGUN_FIRE3_SOUND);

	self.attack_finished = time + HGUN_RATE_TRACK;
	if (self.HGUN_AMMO == 0) self.attack_finished = time + HGUN_RATE_TRACK + HGUN_RechargeTime();

	self.think = Player_Think;
	self.nextthink = time + HGUN_RATE_TRACK;
}

void HGUN_FireDart()
{
	HGUN_Reload();
	if (self.HGUN_AMMO <= 0) return;

	makevectors(self.v_angle + self.punchangle);
	vector base = self.origin + self.view_ofs + v_forward * 16 + v_right * 8 - v_up * 12;

	self.hgun_firePhase = self.hgun_firePhase + 1;
	vector src = base;
	float phase = self.hgun_firePhase;
	if (phase == 1)      src = src + v_up * 8;
	else if (phase == 2) src = src + v_up * 8 + v_right * 8;
	else if (phase == 3) src = src + v_right * 8;
	else if (phase == 4) src = src - v_up * 8 + v_right * 8;
	else if (phase == 5) src = src - v_up * 8;
	else if (phase == 6) src = src - v_up * 8 - v_right * 8;
	else if (phase == 7) src = src - v_right * 8;
	else if (phase == 8) { src = src + v_up * 8 - v_right * 8; self.hgun_firePhase = 0; }

	entity h = Hornet_Create(self, src, self.v_angle);
	h.velocity = v_forward * HORNET_DART_VEL;
	h.angles = vectoangles(h.velocity);

	entity oself = self;
	self = h;
	Hornet_StartDart();
	self = oself;

	self.hgun_rechargeTime = time + HGUN_RechargeTime();
	self.HGUN_AMMO = self.HGUN_AMMO - 1;
	self.currentammo = self.HGUN_AMMO;

	Weapon_SetFrame(HGUN_SHOOT);

	Sound_Play(self, CHAN_WEAPON, 1, Sound_Radius(HGUN_SOUND_RADIUS), PITCH_NORM,
		HGUN_FIRE1_SOUND, HGUN_FIRE2_SOUND, HGUN_FIRE3_SOUND);

	self.attack_finished = time + HGUN_RATE_FAST;
	if (self.HGUN_AMMO == 0) self.attack_finished = time + HGUN_RATE_FAST + 0.5;

	self.think = Player_Think;
	self.nextthink = time + HGUN_RATE_FAST;
}

void HGUN_PrimaryAttack()   { HGUN_FireTrack(); }
void HGUN_SecondaryAttack() { HGUN_FireDart(); }

void HGUN_Switch()
{
	Weapon_SetFrame(HGUN_UP);
	self.reload = TRUE;
	self.think = Player_Think;
	self.nextthink = time + 0.5;

	// HL Holster/Deploy hack: if ammo is 0 on select, seed 1 so the weapon is
	// never "empty and unselectable". The Reload recharge will top it up.
	if (self.HGUN_AMMO <= 0) self.HGUN_AMMO = 1;
	self.hgun_rechargeTime = time + HGUN_RechargeTime();
}

void HGUN_Select()
{
	if (!self.hgun_pickup)
	{
		self.hgun_pickup = TRUE;
		self.HGUN_AMMO = IsMultiplayer() ? HGUN_MAX_CARRY : HGUN_DEFAULT_GIVE;
	}
	self.currentClip = 0;
	self.currentammo = self.HGUN_AMMO;
	self.weaponmodel = HGUN_VIEW_MODEL;
	self.weaponSwitch  = HGUN_Switch;
	self.weaponAttack  = HGUN_PrimaryAttack;
	self.weaponAttack2 = HGUN_SecondaryAttack;
	self.weaponReload  = HGUN_Reload;
	self.weaponSelect  = HGUN_Select;
}

void HGUN_Precache()
{
	precache_model(HGUN_VIEW_MODEL);
	precache_model(HGUN_WORLD_MODEL);
	// precache_model(HGUN_PLAYER_MODEL);
	precache_model(HORNET_MODEL);

	precache_sound(HGUN_FIRE1_SOUND);
	precache_sound(HGUN_FIRE2_SOUND);
	precache_sound(HGUN_FIRE3_SOUND);
	precache_sound(HORNET_BUZZ1_SOUND);
	precache_sound(HORNET_BUZZ2_SOUND);
	precache_sound(HORNET_BUZZ3_SOUND);
	precache_sound(HORNET_HIT1_SOUND);
	precache_sound(HORNET_HIT2_SOUND);
	precache_sound(HORNET_HIT3_SOUND);
}
