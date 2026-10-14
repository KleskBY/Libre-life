#define BSQUID_HEALTH			Skill_GetValue("sk_bullsquid_health", 40)
#define BSQUID_DMG_BITE			Skill_GetValue("sk_bullsquid_dmg_bite", 25)
#define BSQUID_DMG_WHIP			Skill_GetValue("sk_bullsquid_dmg_whip", 25)
#define BSQUID_DMG_SPIT			Skill_GetValue("sk_bullsquid_dmg_spit", 10)

#define BSQUID_SPIT_SPEED		900	// units/s
#define BSQUID_SPIT_RANGE_MIN	64		// don't spit at things within 64 units
#define BSQUID_SPIT_RANGE_MAX	784		// don't spit beyond ~784 units
#define BSQUID_SPIT_Z_LIMIT		256		// don't spit up/down more than this
#define BSQUID_SPRINT_DIST		256	// sprint when within this distance
#define BSQUID_MELEE_DIST		85	// both melee attacks


#define BSQUID_MODEL			"models/bullsquid.iqm"
#define BSQUID_SPIT_MODEL		"sprites/bigspit.spr"	// replaces sprites/bigspit.spr


#define BSQUID_ANIM_IDLE1		7	// idle
#define BSQUID_ANIM_WALK		0	// walk
#define BSQUID_ANIM_RUN			1	// run
#define BSQUID_ANIM_ATTACK_SPIT	10	// range attack wind-up + spit
#define BSQUID_ANIM_ATTACK_BITE	9	// bite lunge
#define BSQUID_ANIM_ATTACK_WHIP	8	// whip (tailwhip)
#define BSQUID_ANIM_HOP			18	// bulljump, hurt-hop jump
#define BSQUID_ANIM_PAIN1		3	// flinchs
#define BSQUID_ANIM_PAIN2		4	// flinchb
#define BSQUID_ANIM_DIE1		16	// die
#define BSQUID_ANIM_DIE2		17	// die1


#define BSQUID_IDLE_SOUND1		"bullchicken/bc_idle1.wav"
#define BSQUID_IDLE_SOUND2		"bullchicken/bc_idle2.wav"
#define BSQUID_IDLE_SOUND3		"bullchicken/bc_idle3.wav"
#define BSQUID_IDLE_SOUND4		"bullchicken/bc_idle4.wav"
#define BSQUID_IDLE_SOUND5		"bullchicken/bc_idle5.wav"

#define BSQUID_PAIN_SOUND1		"bullchicken/bc_pain1.wav"
#define BSQUID_PAIN_SOUND2		"bullchicken/bc_pain2.wav"
#define BSQUID_PAIN_SOUND3		"bullchicken/bc_pain3.wav"
#define BSQUID_PAIN_SOUND4		"bullchicken/bc_pain4.wav"

#define BSQUID_DIE_SOUND1		"bullchicken/bc_die1.wav"
#define BSQUID_DIE_SOUND2		"bullchicken/bc_die2.wav"
#define BSQUID_DIE_SOUND3		"bullchicken/bc_die3.wav"

// Alert reuses two idle sounds pitched up (idle1/2 at pitch 140-160)
#define BSQUID_ALERT_SOUND1		"bullchicken/bc_idle1.wav"
#define BSQUID_ALERT_SOUND2		"bullchicken/bc_idle2.wav"

#define BSQUID_ATTACK_SOUND1	"bullchicken/bc_attack2.wav"	// spit launch
#define BSQUID_ATTACK_SOUND2	"bullchicken/bc_attack3.wav"

#define BSQUID_GROWL_SOUND1		"bullchicken/bc_attackgrowl.wav"	// bite
#define BSQUID_GROWL_SOUND2		"bullchicken/bc_attackgrowl2.wav"
#define BSQUID_GROWL_SOUND3		"bullchicken/bc_attackgrowl3.wav"

#define BSQUID_BITE_SOUND1		"bullchicken/bc_bite2.wav"
#define BSQUID_BITE_SOUND2		"bullchicken/bc_bite3.wav"

#define BSQUID_ACID_SOUND		"bullchicken/bc_acid1.wav"
#define BSQUID_SPITHIT_SOUND1	"bullchicken/bc_spithit1.wav"
#define BSQUID_SPITHIT_SOUND2	"bullchicken/bc_spithit2.wav"


// Spit projectile

void BSpit_Touch()
{
	if (other == self.owner) return;

	// Splat sounds (pitch-shifted)
	float iPitch = 90 + Math_RandomInt(0, 19);
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, BSQUID_ACID_SOUND);
	Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, iPitch, BSQUID_SPITHIT_SOUND1, BSQUID_SPITHIT_SOUND2);

	if (other.takedamage)
	{
		T_Damage(other, self, self.owner, BSQUID_DMG_SPIT, DMG_GENERIC);
	}
	else
	{
		pointparticles(particleeffectnum("TE_GUNSHOT"), self.origin, '0 0 0', 1);
	}

	remove(self);
}

void BSpit_Create(entity creator, vector src, vector vel)
{
	entity spit = spawn();
	spit.classname = "squidspit";
	spit.owner     = creator;
	spit.movetype  = MOVETYPE_FLY;
	spit.solid     = SOLID_BBOX;
	spit.effects  = EF_ADDITIVE;	// FTE needs the flag for .spr transparency
	setmodel(spit, BSQUID_SPIT_MODEL);
	setsize(spit, '0 0 0', '0 0 0');
	setorigin(spit, src);
	spit.colormod = '0.1 0.8 0.2';
	spit.velocity  = vel;
	spit.angles    = vectoangles(vel);
	spit.touch     = BSpit_Touch;
	spit.think     = SUB_Remove;
	spit.nextthink = time + 6;	// failsafe cleanup
}


void BSquid_Run();	// forward decl

void BSquid_DoSpit()
{
	if (!self.enemy) return;

	makevectors(self.angles);

	vector src = self.origin + v_right * 8 + v_forward * 37 + v_up * 23;
	vector dir = normalize(self.enemy.origin + self.enemy.view_ofs - src);

	// Small random spread
	dir_x += random() * 0.1 - 0.05;
	dir_y += random() * 0.1 - 0.05;
	dir_z -= random() * 0.05;	// slight droop bias (z only negative)
	dir = normalize(dir);

	// Attack sound (the "spitting" grunt)
	Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, 100, BSQUID_ATTACK_SOUND1, BSQUID_ATTACK_SOUND2);

	BSpit_Create(self, src, dir * BSQUID_SPIT_SPEED);
}

void BSquid_SpitThink()
{
	self.timer += 1;
	AI_Face();

	if (self.timer == 4)
		BSquid_DoSpit();

	if (self.timer > 6)
	{
		self.think     = BSquid_Run;
		self.nextthink = time + 0.1;
		return;
	}

	self.think     = BSquid_SpitThink;
	self.nextthink = time + 0.1;
}

void BSquid_SpitMissile()
{
	self.timer = 0;
	self.frame = BSQUID_ANIM_ATTACK_SPIT;
	BSquid_SpitThink();
}


// Melee attacks

// Deals BSQUID_DMG_WHIP with DMG_CLUB | DMG_ALWAYSGIB (always gibs).
void BSquid_TailwhipStroke()
{
	makevectors(self.angles);
	entity pHurt = Combat_CheckTraceHullAttack(BSQUID_MELEE_DIST, BSQUID_DMG_WHIP, DMG_CLUB | DMG_ALWAYSGIB);
	if (pHurt)
	{
		pHurt.punchangle_z =  -20;
		pHurt.punchangle_x =   20;
		pHurt.velocity     = pHurt.velocity + v_right * 200;
		pHurt.velocity_z  += 100;
	}
}

void BSquid_WhipThink()
{
	self.timer += 1;
	AI_Charge(6);

	if (self.timer == 3) BSquid_TailwhipStroke();

	if (self.timer > 10)
	{
		self.think     = BSquid_Run;
		self.nextthink = time + 0.1;
		return;
	}

	self.think     = BSquid_WhipThink;
	self.nextthink = time + 0.1;
}

void BSquid_BiteStroke()
{
	makevectors(self.angles);
	entity pHurt = Combat_CheckTraceHullAttack(BSQUID_MELEE_DIST, BSQUID_DMG_BITE, DMG_SLASH);
	if (pHurt)
	{
		pHurt.velocity    = pHurt.velocity - v_forward * 100;
		pHurt.velocity_z += 100;
	}
	Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, 90 + Math_RandomInt(0, 19), BSQUID_BITE_SOUND1, BSQUID_BITE_SOUND2);
}

void BSquid_BiteThink()
{
	self.timer += 1;
	AI_Charge(8);

	if (self.timer == 3) BSquid_BiteStroke();

	if (self.timer > 10)
	{
		self.think     = BSquid_Run;
		self.nextthink = time + 0.1;
		return;
	}

	self.think     = BSquid_BiteThink;
	self.nextthink = time + 0.1;
}

void BSquid_Melee()
{
	self.timer = 0;

	if (self.enemy && self.enemy.health <= BSQUID_DMG_WHIP)
	{
		Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100, BSQUID_GROWL_SOUND1, BSQUID_GROWL_SOUND2, BSQUID_GROWL_SOUND3);
		self.frame = BSQUID_ANIM_ATTACK_WHIP;
		BSquid_WhipThink();
	}
	else
	{
		Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100, BSQUID_GROWL_SOUND1, BSQUID_GROWL_SOUND2, BSQUID_GROWL_SOUND3);
		self.frame = BSQUID_ANIM_ATTACK_BITE;
		BSquid_BiteThink();
	}
}


// Custom attack check
// Handles spit range conditions and melee priority.
float BSquid_CheckAttack()
{
	entity targ = self.enemy;
	if (!targ) return FALSE;

	traceline(self.origin + self.view_ofs, targ.origin + targ.view_ofs, FALSE, self);
	if (trace_ent != targ)        return FALSE;
	if (trace_inopen && trace_inwater) return FALSE;

	makevectors(self.angles);
	float flDist = vlen(targ.origin - self.origin);
	float flDot  = normalize(targ.origin - self.origin) * v_forward;

	// CheckMeleeAttack1 (whip) gate: enemy HP <= whipDmg, dist <= 85, dot >= 0.7
	// CheckMeleeAttack2 (bite) gate: dist <= 85, dot >= 0.7, no-whip-available
	if (flDist <= BSQUID_MELEE_DIST && flDot >= 0.7)
	{
		if (time < self.attack_finished) return FALSE;
		self.attack_finished = time + 1 + random();
		self.th_melee();
		return TRUE;
	}

	if (time >= self.m_flNextAttack
		&& flDist > BSQUID_SPIT_RANGE_MIN
		&& flDist <= BSQUID_SPIT_RANGE_MAX
		&& flDot >= 0.5
		&& fabs(targ.origin_z - self.origin_z) < BSQUID_SPIT_Z_LIMIT)
	{
		// Don't stop to spit if we're sprinting and still far away
		if (vlen(self.velocity) > 10 && flDist >= 512) return FALSE;

		self.th_missile();

		// Refire cooldown: short when stationary, long when running
		if (vlen(self.velocity) > 10)
			self.m_flNextAttack = time + 5;
		else
			self.m_flNextAttack = time + 0.5;

		return TRUE;
	}

	return FALSE;
}


// AI states

// Randomly blink the eye by toggling skin 0 (open) / 1 (closed).
// Called at the top of each state think. Mirrors RunAI skin logic.
void BSquid_BlinkEye()
{
	if (self.skin == 1) self.skin = 0;
	else if (random() < 0.025) self.skin = 1;	// ~1/40 chance each tick
}

void BSquid_Stand()
{
	if (Monster_YieldIfDead()) return;
	if (Monster_YieldToCine(BSquid_Stand)) return;
	BSquid_BlinkEye();
	self.frame     = BSQUID_ANIM_IDLE1;
	self.think     = BSquid_Stand;
	self.nextthink = time + 0.1;
	AI_Stand();
	if (random() > 0.95 && !(self.spawnflags & SF_MONSTER_GAG))
		Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100,
		BSQUID_IDLE_SOUND1, BSQUID_IDLE_SOUND2, BSQUID_IDLE_SOUND3,
		BSQUID_IDLE_SOUND4, BSQUID_IDLE_SOUND5);
}

void BSquid_Walk()
{
	if (Monster_YieldIfDead()) return;
	if (Monster_YieldToCine(BSquid_Walk)) return;
	BSquid_BlinkEye();
	self.frame     = BSQUID_ANIM_WALK;
	self.think     = BSquid_Walk;
	self.nextthink = time + 0.1;
	AI_Walk(8);
	if (random() > 0.95 && !(self.spawnflags & SF_MONSTER_GAG))
		Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100,
		BSQUID_IDLE_SOUND1, BSQUID_IDLE_SOUND2, BSQUID_IDLE_SOUND3);
}

void BSquid_Run()
{
	if (Monster_YieldIfDead()) return;
	if (Monster_YieldToCine(BSquid_Run)) return;
	BSquid_BlinkEye();
	self.frame = BSQUID_ANIM_RUN;

	float speed = 18;
	if (self.enemy)
	{
		float flDist = vlen(self.enemy.origin - self.origin);
		if (flDist < BSQUID_SPRINT_DIST)
			speed = 28;	// framerate = 1.25 boost
	}

	self.think     = BSquid_Run;
	self.nextthink = time + 0.1;
	AI_Run(speed);
}


void BSquid_AlertSound()
{
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 140 + Math_RandomInt(0, 19), BSQUID_ALERT_SOUND1, BSQUID_ALERT_SOUND2);
}


// Launches the squid into the air and makes it face the attacker.
// velocity_z formula: (0.625 * gravity) * 0.5 = 250 at g=800
void BSquid_Pain(entity attacker, float damage)
{
	if (self.pain_finished > time) return;
	self.pain_finished = time + 2;

	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 85 + Math_RandomInt(0, 34),
		BSQUID_PAIN_SOUND1, BSQUID_PAIN_SOUND2, BSQUID_PAIN_SOUND3, BSQUID_PAIN_SOUND4);

	if (self.flags & FL_ONGROUND)
	{
		self.flags    = self.flags - (self.flags & FL_ONGROUND);
		self.velocity_z += 250;
	}

	self.frame     = (random() > 0.5) ? BSQUID_ANIM_PAIN1 : BSQUID_ANIM_PAIN2;
	self.ideal_yaw = vectoyaw(attacker.origin - self.origin);

	self.think     = BSquid_Run;
	self.nextthink = time + 0.5;
}


void BSquid_Die()
{
	if (self.health < GIB_HEALTH_VALUE)
	{
		Gib();
		return;
	}

	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100, BSQUID_DIE_SOUND1, BSQUID_DIE_SOUND2, BSQUID_DIE_SOUND3);

	self.frame = (random() > 0.5) ? BSQUID_ANIM_DIE1 : BSQUID_ANIM_DIE2;

	self.solid     = SOLID_CORPSE;
	setsize(self, '-32 -32 0', '32 32 8');
	self.think     = SUB_Remove;
	self.nextthink = time + 120;
}


void BSquid_Precache()
{
	precache_model(BSQUID_MODEL);
	precache_model(BSQUID_SPIT_MODEL);

	precache_sound(BSQUID_IDLE_SOUND1);
	precache_sound(BSQUID_IDLE_SOUND2);
	precache_sound(BSQUID_IDLE_SOUND3);
	precache_sound(BSQUID_IDLE_SOUND4);
	precache_sound(BSQUID_IDLE_SOUND5);

	precache_sound(BSQUID_PAIN_SOUND1);
	precache_sound(BSQUID_PAIN_SOUND2);
	precache_sound(BSQUID_PAIN_SOUND3);
	precache_sound(BSQUID_PAIN_SOUND4);

	precache_sound(BSQUID_DIE_SOUND1);
	precache_sound(BSQUID_DIE_SOUND2);
	precache_sound(BSQUID_DIE_SOUND3);

	precache_sound(BSQUID_ATTACK_SOUND1);
	precache_sound(BSQUID_ATTACK_SOUND2);

	precache_sound(BSQUID_GROWL_SOUND1);
	precache_sound(BSQUID_GROWL_SOUND2);
	precache_sound(BSQUID_GROWL_SOUND3);

	precache_sound(BSQUID_BITE_SOUND1);
	precache_sound(BSQUID_BITE_SOUND2);

	precache_sound(BSQUID_ACID_SOUND);
	precache_sound(BSQUID_SPITHIT_SOUND1);
	precache_sound(BSQUID_SPITHIT_SOUND2);
}


void monster_bullchicken()
{
	if (Monster_RemoveIfSpent()) return;
	if(RemoveInDeathmatch()) return;

	BSquid_Precache();

	self.solid         = SOLID_SLIDEBOX;
	self.movetype      = MOVETYPE_STEP;
	self.yaw_speed     = YAW_HL(90);
	self.health        = BSQUID_HEALTH;
	self.view_ofs      = '0 0 48';
	self.monster_state = MONSTERSTATE_NONE;
	self.monster_capability = BITS_CAP_HEAR | BITS_CAP_RANGE_ATTACK1
	                    | BITS_CAP_MELEE_ATTACK1 | BITS_CAP_MELEE_ATTACK2;
	setmodel(self, BSQUID_MODEL);
	setsize(self, '-32 -32 0', '32 32 64');

	self.th_stand    = BSquid_Stand;
	self.th_walk     = BSquid_Walk;
	self.th_run      = BSquid_Run;
	self.th_melee    = BSquid_Melee;
	self.th_missile  = BSquid_SpitMissile;
	self.th_pain     = BSquid_Pain;
	self.th_die      = BSquid_Die;
	self.sightSound  = BSquid_AlertSound;
	self.checkAttack = BSquid_CheckAttack;
	self.goalentity  = world;
	self.enemy       = world;

	Monster_InitTakeDamage();

	WalkMonster_Start();
}
