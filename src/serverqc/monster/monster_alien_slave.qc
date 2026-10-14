
#define ISLAVE_HEALTH			Skill_GetValue("sk_islave_health", 30)
#define ISLAVE_DMG_CLAW			Skill_GetValue("sk_islave_dmg_claw", 30)
#define ISLAVE_DMG_CLAWRAKE		Skill_GetValue("sk_islave_dmg_clawrake", 25)
#define ISLAVE_DMG_ZAP			Skill_GetValue("sk_islave_dmg_zap", 24)
#define ISLAVE_ZAP_RANGE		1024	// trace length for both beams
#define ISLAVE_ZAP_REFIRE_MIN	0.5		// soonest refire after a zap
#define ISLAVE_ZAP_REFIRE_RAND	3.5


#define ISLAVE_MODEL			"models/islave.iqm"

// Animation sequence indices (match islave.mdl)
// Each index corresponds to the sequence number in the .iqm file.

#define ISLAVE_ANIM_IDLE1		0
#define ISLAVE_ANIM_IDLE2		1
#define ISLAVE_ANIM_IDLE3		2
#define ISLAVE_ANIM_WALK		4
#define ISLAVE_ANIM_RUN			6
#define ISLAVE_ANIM_ATTACK1		11	// claw swing
#define ISLAVE_ANIM_ATTACK2		6	// claw rake
#define ISLAVE_ANIM_ZAP			12
#define ISLAVE_ANIM_ZAP_POWERUP	7
#define ISLAVE_ANIM_ZAP_SHOOT	8
#define ISLAVE_ANIM_ZAP_DONE	9
#define ISLAVE_ANIM_PAIN1		10
#define ISLAVE_ANIM_PAIN2		11
#define ISLAVE_ANIM_DIE_HEAD	18
#define ISLAVE_ANIM_DIE1		19
#define ISLAVE_ANIM_DIE2		20
#define ISLAVE_ANIM_DIE3		21


#define ISLAVE_PAIN_SOUND1		"aslave/slv_pain1.wav"
#define ISLAVE_PAIN_SOUND2		"aslave/slv_pain2.wav"
#define ISLAVE_DIE_SOUND1		"aslave/slv_die1.wav"
#define ISLAVE_DIE_SOUND2		"aslave/slv_die2.wav"
#define ISLAVE_ATTACK_HIT1		"zombie/claw_strike1.wav"
#define ISLAVE_ATTACK_HIT2		"zombie/claw_strike2.wav"
#define ISLAVE_ATTACK_HIT3		"zombie/claw_strike3.wav"
#define ISLAVE_ATTACK_MISS1		"zombie/claw_miss1.wav"
#define ISLAVE_ATTACK_MISS2		"zombie/claw_miss2.wav"
// Zap sounds
#define ISLAVE_ZAP_POWERUP_SOUND "debris/zap4.wav"
#define ISLAVE_ZAP_SHOOT_SOUND	"hassault/hw_shoot1.wav"
#define ISLAVE_ZAP_HIT_SOUND	"weapons/electro4.wav"


// ZAP beam helpers

// Called during ZAP_POWERUP wind-up; no damage. side = -1 (left) or 1 (right).
void ISlave_ArmBeam(float side)
{
	makevectors(self.angles);
	vector src = self.origin + v_up * 36 + v_right * side * 16 + v_forward * 32;

	// Try 3 random sideways/vertical traces; keep the closest surface hit.
	float best   = 1.0;
	vector bestEnd = src;
	for (float i = 0; i < 3; i++)
	{
		vector dir = normalize(v_right * side * random() + v_up * (random() * 2 - 1));
		traceline(src, src + dir * 512, TRUE, self);
		if (trace_fraction < best)
		{
			best    = trace_fraction;
			bestEnd = trace_endpos;
		}
	}

	if (best < 1.0)
		te_lightning2(self, src, bestEnd);
}

void ISlave_ZapBeam(float side)
{
	if (!self.enemy) return;
	makevectors(self.angles);

	vector src = self.origin + v_up * 36;
	vector aim = normalize(self.enemy.origin + self.enemy.view_ofs - src);

	// Uses a 0.01-unit deflection per beam
	float defl = 0.01;
	aim = normalize(aim
		+ v_right * side * (random() * defl)
		+ v_up             * (random() * defl - defl * 0.5));

	traceline(src, src + aim * ISLAVE_ZAP_RANGE, FALSE, self);
	te_lightning2(self, src, trace_endpos);

	if (trace_ent != world && trace_ent.takedamage)
		AddMultiDamage(trace_ent, ISLAVE_DMG_ZAP, DMG_SHOCK);

	// Quiet zap noise at impact point (ambient-style, low volume)
	Sound_Play(self, CHAN_AUTO, 0.5, ATTN_NORM, PITCH_NORM, ISLAVE_ZAP_HIT_SOUND);
}


void ISlave_Run();	// forward decl for think chain

void ISlave_ZapThink()
{
	self.timer += 1;
	AI_Face();

	if (self.timer <= 8)
	{
		self.skin  = (self.timer - 1) >> 1;
		ISlave_ArmBeam(-1);
		ISlave_ArmBeam( 1);
	}
	else if (self.timer == 9)
	{
		self.skin  = 0;

		ClearMultiDamage();
		ISlave_ZapBeam(-1);
		ISlave_ZapBeam( 1);
		Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, ISLAVE_ZAP_SHOOT_SOUND);
		ApplyMultiDamage();

		// random refire window matching RANDOM_FLOAT(0.5, 4.0)
		self.m_flNextAttack = time + ISLAVE_ZAP_REFIRE_MIN + random() * ISLAVE_ZAP_REFIRE_RAND;
	}
	else
	{
		self.skin  = 0;
		self.think     = ISlave_Run;
		self.nextthink = time + 0.1;
		return;
	}

	self.think     = ISlave_ZapThink;
	self.nextthink = time + 0.1;
}

void ISlave_ZapMissile()
{
	if (time < self.m_flNextAttack) return;

	self.timer = 0;
	self.frame = ISLAVE_ANIM_ZAP;
	Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, ISLAVE_ZAP_POWERUP_SOUND);
	ISlave_ZapThink();
}


void ISlave_ClawStroke(float bRake)
{
	makevectors(self.angles);

	entity pHurt;
	if (bRake)
	{
		self.frame = ISLAVE_ANIM_ATTACK2;
		pHurt = Combat_CheckTraceHullAttack(70, ISLAVE_DMG_CLAWRAKE, DMG_SLASH);
	}
	else
	{
		self.frame = ISLAVE_ANIM_ATTACK1;
		pHurt = Combat_CheckTraceHullAttack(70, ISLAVE_DMG_CLAW, DMG_SLASH);
	}

	if (pHurt)
	{
		if (pHurt.flags & (FL_MONSTER | FL_CLIENT))
		{
			pHurt.punchangle_x =  5;
			pHurt.punchangle_z = bRake ? 18 : -18;
		}
		Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, 95 + Math_RandomInt(0, 9),
			ISLAVE_ATTACK_HIT1, ISLAVE_ATTACK_HIT2, ISLAVE_ATTACK_HIT3);
	}
	else
	{
		Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, 95 + Math_RandomInt(0, 9),
			ISLAVE_ATTACK_MISS1, ISLAVE_ATTACK_MISS2);
	}
}

void ISlave_MeleeThink()
{
	self.timer += 1;
	AI_Charge(4);

	if (self.timer == 4)  ISlave_ClawStroke(FALSE);
	if (self.timer == 10) ISlave_ClawStroke(random() > 0.5);	// random rake

	if (self.timer > 14)
	{
		self.think     = ISlave_Run;
		self.nextthink = time + 0.1;
		return;
	}

	self.think     = ISlave_MeleeThink;
	self.nextthink = time + 0.1;
}

void ISlave_Melee()
{
	self.timer = 0;
	ISlave_MeleeThink();
}


float ISlave_CheckAttack()
{
	entity targ = self.enemy;
	if (!targ) return FALSE;

	traceline(self.origin + self.view_ofs, targ.origin + targ.view_ofs, FALSE, self);
	if (trace_ent != targ)  return FALSE;
	if (trace_inopen && trace_inwater) return FALSE;

	// Always prefer melee when the target is right in front of us
	if (enemy_range == RANGE_MELEE && self.th_melee)
	{
		self.th_melee();
		return TRUE;
	}

	if (!self.th_missile)          return FALSE;
	if (time < self.attack_finished) return FALSE;
	if (time < self.m_flNextAttack)  return FALSE;
	if (enemy_range == RANGE_FAR)    return FALSE;

	float chance = 0;
	if      (enemy_range == RANGE_NEAR) chance = 0.2;
	else if (enemy_range == RANGE_MID)  chance = 0.05;

	if (random() < chance)
	{
		self.th_missile();
		self.attack_finished = time + random() * 2;
		return TRUE;
	}
	return FALSE;
}


void ISlave_Stand()
{
	if (Monster_YieldIfDead()) return;
	if (Monster_YieldToCine(ISlave_Stand)) return;
	self.frame     = ISLAVE_ANIM_IDLE3;
	self.think     = ISlave_Stand;
	self.nextthink = time + 0.1;
	AI_Stand();
}

void ISlave_Walk()
{
	if (Monster_YieldIfDead()) return;
	if (Monster_YieldToCine(ISlave_Walk)) return;
	self.frame     = ISLAVE_ANIM_WALK;
	self.think     = ISlave_Walk;
	self.nextthink = time + 0.1;
	AI_Walk(8);
}

void ISlave_Run()
{
	if (Monster_YieldIfDead()) return;
	if (Monster_YieldToCine(ISlave_Run)) return;
	self.frame     = ISLAVE_ANIM_RUN;
	self.think     = ISlave_Run;
	self.nextthink = time + 0.1;
	AI_Run(16);
}


// Alert sound (fires on first sight of enemy)
void ISlave_AlertSound()
{
	Sound_Play(self, CHAN_VOICE, 0.85, ATTN_NORM, 85 + Math_RandomInt(0, 24), ISLAVE_PAIN_SOUND1, ISLAVE_PAIN_SOUND2);
}


void ISlave_Pain(entity attacker, float damage)
{
	if (self.pain_finished > time) return;
	if (random() > 0.33) return;	// Only plays pain approximately 1/3 of the time

	self.pain_finished = time + 1;

	Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, 85 + Math_RandomInt(0, 24), ISLAVE_PAIN_SOUND1, ISLAVE_PAIN_SOUND2);
	self.frame = (random() > 0.5) ? ISLAVE_ANIM_PAIN1 : ISLAVE_ANIM_PAIN2;
	self.skin  = 0;	// clear any zap glow

	self.think     = ISlave_Run;
	self.nextthink = time + 0.3;
}


void ISlave_Die()
{
	self.skin = 0;	// clear glow on death

	if (self.health < GIB_HEALTH_VALUE)
	{
		Gib();
		return;
	}

	Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, 85 + Math_RandomInt(0, 24), ISLAVE_DIE_SOUND1, ISLAVE_DIE_SOUND2);
	self.frame = (random() > 0.5) ? ISLAVE_ANIM_DIE1 : ISLAVE_ANIM_DIE2;
	self.solid = SOLID_CORPSE;
	setsize(self, VEC_HUMAN_HULL_MIN, '16 16 4');
	self.think     = SUB_Remove;
	self.nextthink = time + 120;
}


float ISlave_TakeDamage(entity inflictor, entity attacker, float damage, float dmgType)
{
	// Slaves are immune to their own lightning (and each other's)
	if (dmgType & DMG_SHOCK) return 0;

	Monster_Remember(BITS_MEMORY_PROVOKED);
	return Monster_TakeDamage(inflictor, attacker, damage, dmgType);
}


void ISlave_Precache()
{
	precache_model(ISLAVE_MODEL);

	precache_sound(ISLAVE_PAIN_SOUND1);
	precache_sound(ISLAVE_PAIN_SOUND2);
	precache_sound(ISLAVE_DIE_SOUND1);
	precache_sound(ISLAVE_DIE_SOUND2);

	precache_sound(ISLAVE_ATTACK_HIT1);
	precache_sound(ISLAVE_ATTACK_HIT2);
	precache_sound(ISLAVE_ATTACK_HIT3);
	precache_sound(ISLAVE_ATTACK_MISS1);
	precache_sound(ISLAVE_ATTACK_MISS2);

	precache_sound(ISLAVE_ZAP_POWERUP_SOUND);
	precache_sound(ISLAVE_ZAP_SHOOT_SOUND);
	precache_sound(ISLAVE_ZAP_HIT_SOUND);
}


void monster_alien_slave()
{
	if (Monster_RemoveIfSpent()) return;
	if(RemoveInDeathmatch()) return;

	ISlave_Precache();

	self.solid         = SOLID_SLIDEBOX;
	self.movetype      = MOVETYPE_STEP;
	self.yaw_speed     = YAW_HL(90);	// SetYawSpeed default
	self.health        = ISLAVE_HEALTH;
	self.view_ofs      = '0 0 64';
	self.monster_state = MONSTERSTATE_NONE;
	self.monster_capability = BITS_CAP_HEAR | BITS_CAP_TURN_HEAD
	                    | BITS_CAP_RANGE_ATTACK1 | BITS_CAP_MELEE_ATTACK1
	                    | BITS_CAP_DOORS_GROUP;
	setmodel(self, ISLAVE_MODEL);
	setsize(self, VEC_HUMAN_HULL_MIN, VEC_HUMAN_HULL_MAX);

	self.th_stand   = ISlave_Stand;
	self.th_walk    = ISlave_Walk;
	self.th_run     = ISlave_Run;
	self.th_melee   = ISlave_Melee;
	self.th_missile = ISlave_ZapMissile;
	self.th_pain    = ISlave_Pain;
	self.th_die     = ISlave_Die;
	self.sightSound = ISlave_AlertSound;
	self.checkAttack = ISlave_CheckAttack;
	self.goalentity = world;
	self.enemy      = world;

	Monster_InitTakeDamage();
	self.takeDmgFn = ISlave_TakeDamage;	// override: shock immunity + provoked flag

	WalkMonster_Start();
}
