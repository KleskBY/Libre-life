
#define HEADCRAB_MODEL				"models/headcrab.iqm"

#define HEADCRAB_IDLE_SOUND1		"headcrab/hc_idle1.wav"
#define HEADCRAB_IDLE_SOUND2		"headcrab/hc_idle2.wav"
#define HEADCRAB_IDLE_SOUND3		"headcrab/hc_idle3.wav"

#define HEADCRAB_ALERT_SOUND1		"headcrab/hc_alert1.wav"

#define HEADCRAB_PAIN_SOUND1		"headcrab/hc_pain1.wav"
#define HEADCRAB_PAIN_SOUND2		"headcrab/hc_pain2.wav"
#define HEADCRAB_PAIN_SOUND3		"headcrab/hc_pain3.wav"

#define HEADCRAB_ATTACK_SOUND1		"headcrab/hc_attack1.wav"
#define HEADCRAB_ATTACK_SOUND2		"headcrab/hc_attack2.wav"
#define HEADCRAB_ATTACK_SOUND3		"headcrab/hc_attack3.wav"

#define HEADCRAB_DIE_SOUND1			"headcrab/hc_die1.wav"
#define HEADCRAB_DIE_SOUND2			"headcrab/hc_die2.wav"

#define HEADCRAB_BITE_SOUND1		"headcrab/hc_headbite.wav"

#define HEADCRAB_HEALTH				Skill_GetValue("sk_headcrab_health", 20)
#define HEADCRAB_DMG_BITE			Skill_GetValue("sk_headcrab_dmg_bite", 10)

// Scale bite damage at runtime (babycrab sets this to 0.3). 0/unset = 1.0.
.float headcrab_dmgmult;
#define HEADCRAB_LEAP_RANGE			400		// max distance to start a leap
#define HEADCRAB_LEAP_SPEED_CAP		650	// caps leap velocity at 650

#define HEADCRAB_ANIMATION_IDLE1	0
#define HEADCRAB_ANIMATION_IDLE2	1
#define HEADCRAB_ANIMATION_IDLE3	2
#define HEADCRAB_ANIMATION_WALK		3
#define HEADCRAB_ANIMATION_RUN		4
#define HEADCRAB_ANIMATION_PAIN		6
#define HEADCRAB_ANIMATION_DIE		7
#define HEADCRAB_ANIMATION_JUMP		10

void Headcrab_IdleSound()
{
	if (self.spawnflags & SF_MONSTER_GAG) return;
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100, HEADCRAB_IDLE_SOUND1, HEADCRAB_IDLE_SOUND2, HEADCRAB_IDLE_SOUND3);
}

void Headcrab_AlertSound()
{
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, HEADCRAB_ALERT_SOUND1);
}

void Headcrab_PainSound()
{
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100, HEADCRAB_PAIN_SOUND1, HEADCRAB_PAIN_SOUND2, HEADCRAB_PAIN_SOUND3);
}

void Headcrab_DieSound()
{
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100, HEADCRAB_DIE_SOUND1, HEADCRAB_DIE_SOUND2);
}

void Headcrab_AttackSound()
{
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100, HEADCRAB_ATTACK_SOUND1, HEADCRAB_ATTACK_SOUND2, HEADCRAB_ATTACK_SOUND3);
}

void Headcrab_Stand()
{
	if (Monster_YieldToCine(Headcrab_Stand)) return;
	self.frame = HEADCRAB_ANIMATION_IDLE1;
	self.think = Headcrab_Stand;
	self.nextthink = time + 0.1;
	AI_Stand();
	if (random() > 0.95) Headcrab_IdleSound();
}

void Headcrab_Walk()
{
	if (Monster_YieldToCine(Headcrab_Walk)) return;
	self.frame = HEADCRAB_ANIMATION_WALK;
	self.think = Headcrab_Walk;
	self.nextthink = time + 0.1;
	AI_Walk(5);
	if (random() > 0.95) Headcrab_IdleSound();
}

void Headcrab_Run()
{
	if (Monster_YieldToCine(Headcrab_Run)) return;
	self.frame = HEADCRAB_ANIMATION_RUN;
	self.think = Headcrab_Run;
	self.nextthink = time + 0.1;
	AI_Run(8);
	if (random() > 0.95) Headcrab_IdleSound();
}

// Computes a ballistic arc toward the enemy's eyes and enables a touch callback that deals damage on contact
void Headcrab_LeapTouch()
{
	if (other == world)
	{
		self.touch = SUB_Null;
		self.think = Headcrab_Run;
		self.nextthink = time + 0.1;
		return;
	}

	if (!other.takedamage) return;
	if (other.classname == self.classname) return;	// don't bite other headcrabs

	// Only deal damage while airborne
	if (!(self.flags & FL_ONGROUND))
	{
		Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, HEADCRAB_BITE_SOUND1);
		float mult = (self.headcrab_dmgmult > 0) ? self.headcrab_dmgmult : 1;
		T_Damage(other, self, self, HEADCRAB_DMG_BITE * mult);
	}

	self.touch = SUB_Null;
}

void Headcrab_LeapThink()
{
	// Wait until the leap animation winds up, then jump
	self.timer = self.timer + 1;

	if (self.timer < 5)
	{
		AI_Face();
		self.think = Headcrab_LeapThink;
		self.nextthink = time + 0.1;
		return;
	}

	// Launch!
	self.flags = self.flags - (self.flags & FL_ONGROUND);
	setorigin(self, self.origin + '0 0 1');	// nudge off ground so engine doesn't reset FL_ONGROUND

	if (self.enemy)
	{
		// Compute ballistic jump toward enemy's eyes
		float gravity = cvar("sv_gravity");
		if (gravity <= 1) gravity = 1;

		float height = (self.enemy.origin_z + self.enemy.view_ofs_z) - self.origin_z;
		if (height < 16) height = 16;

		float spd = sqrt(2 * gravity * height);
		float flytime = spd / gravity;

		vector jumpDir = self.enemy.origin + self.enemy.view_ofs - self.origin;
		jumpDir_x = jumpDir_x * (1.0 / flytime);
		jumpDir_y = jumpDir_y * (1.0 / flytime);
		jumpDir_z = spd;

		// Cap velocity
		float dist = vlen(jumpDir);
		if (dist > HEADCRAB_LEAP_SPEED_CAP)
			jumpDir = jumpDir * (HEADCRAB_LEAP_SPEED_CAP / dist);

		self.velocity = jumpDir;
	}
	else
	{
		makevectors(self.angles);
		self.velocity = v_forward * 300 + '0 0 200';
	}

	Headcrab_AttackSound();
	self.touch = Headcrab_LeapTouch;

	self.think = Headcrab_Run;
	self.nextthink = time + 2;	// fallback if we never land
}

void Headcrab_Attack()
{
	self.timer = 0;
	self.frame = HEADCRAB_ANIMATION_JUMP;
	AI_Face();
	Headcrab_LeapThink();
}

float Headcrab_CheckAttack()
{
	if (!self.enemy) return FALSE;
	if (!(self.flags & FL_ONGROUND)) return FALSE;
	if (time < self.attack_finished) return FALSE;

	traceline(self.origin + self.view_ofs, self.enemy.origin + self.enemy.view_ofs, FALSE, self);
	if (trace_ent != self.enemy) return FALSE;

	vector dir = normalize(self.enemy.origin - self.origin);
	makevectors(self.angles);
	float flDot = dir * v_forward;
	float flDist = vlen(self.enemy.origin - self.origin);

	if (flDist <= HEADCRAB_LEAP_RANGE && flDot >= 0.65)
	{
		Headcrab_Attack();
		self.attack_finished = time + 2;
		return TRUE;
	}

	return FALSE;
}

void Headcrab_Pain(entity attacker, float damage)
{
	if (self.pain_finished > time) return;
	self.pain_finished = time + 1;
	Headcrab_PainSound();
	self.frame = 3;
	self.think = Headcrab_Run;
	self.nextthink = time + 0.5;
}

void Headcrab_Die()
{
	if (Gib_ShouldGib())
	{
		Gib();
		return;
	}

	Headcrab_DieSound();
	self.frame = HEADCRAB_ANIMATION_DIE;
	self.solid = SOLID_CORPSE;
	setsize(self, '-12 -12 0', '12 12 8');
	self.think = SUB_Remove;
	self.nextthink = time + 120;
}

void Headcrab_Precache()
{
	precache_model(HEADCRAB_MODEL);

	precache_sound(HEADCRAB_IDLE_SOUND1);
	precache_sound(HEADCRAB_IDLE_SOUND2);
	precache_sound(HEADCRAB_IDLE_SOUND3);

	precache_sound(HEADCRAB_ALERT_SOUND1);

	precache_sound(HEADCRAB_PAIN_SOUND1);
	precache_sound(HEADCRAB_PAIN_SOUND2);
	precache_sound(HEADCRAB_PAIN_SOUND3);

	precache_sound(HEADCRAB_ATTACK_SOUND1);
	precache_sound(HEADCRAB_ATTACK_SOUND2);
	precache_sound(HEADCRAB_ATTACK_SOUND3);

	precache_sound(HEADCRAB_DIE_SOUND1);
	precache_sound(HEADCRAB_DIE_SOUND2);

	precache_sound(HEADCRAB_BITE_SOUND1);
}

void monster_headcrab()
{
	if (Monster_RemoveIfSpent()) return;
	if(RemoveInDeathmatch()) return;

	Headcrab_Precache();
	self.solid			= SOLID_SLIDEBOX;
	self.movetype		= MOVETYPE_STEP;
	self.yaw_speed		= 30;
	self.health			= HEADCRAB_HEALTH;
	self.view_ofs		= '0 0 20';
	self.monster_state	= MONSTERSTATE_NONE;
	setmodel(self, HEADCRAB_MODEL);
	setsize(self, '-12 -12 0', '12 12 24');

	self.th_stand	= Headcrab_Stand;
	self.th_walk	= Headcrab_Walk;
	self.th_run		= Headcrab_Run;
	self.th_melee	= Headcrab_Attack;
	self.th_pain	= Headcrab_Pain;
	self.th_die		= Headcrab_Die;
	self.sightSound	= Headcrab_AlertSound;
	self.checkAttack = Headcrab_CheckAttack;
	Monster_InitTakeDamage();
	WalkMonster_Start();
}
