
#define HOUNDEYE_MODEL				"models/houndeye.iqm"

#define HOUNDEYE_IDLE_SOUND1		"houndeye/he_idle1.wav"
#define HOUNDEYE_IDLE_SOUND2		"houndeye/he_idle2.wav"
#define HOUNDEYE_IDLE_SOUND3		"houndeye/he_idle3.wav"

#define HOUNDEYE_ALERT_SOUND1		"houndeye/he_alert1.wav"
#define HOUNDEYE_ALERT_SOUND2		"houndeye/he_alert2.wav"
#define HOUNDEYE_ALERT_SOUND3		"houndeye/he_alert3.wav"

#define HOUNDEYE_HUNT_SOUND1		"houndeye/he_hunt1.wav"
#define HOUNDEYE_HUNT_SOUND2		"houndeye/he_hunt2.wav"
#define HOUNDEYE_HUNT_SOUND3		"houndeye/he_hunt3.wav"

#define HOUNDEYE_PAIN_SOUND1		"houndeye/he_pain3.wav"
#define HOUNDEYE_PAIN_SOUND2		"houndeye/he_pain4.wav"
#define HOUNDEYE_PAIN_SOUND3		"houndeye/he_pain5.wav"

#define HOUNDEYE_ANGER_SOUND1		"houndeye/he_pain3.wav"
#define HOUNDEYE_ANGER_SOUND2		"houndeye/he_pain1.wav"

#define HOUNDEYE_DIE_SOUND1			"houndeye/he_die1.wav"
#define HOUNDEYE_DIE_SOUND2			"houndeye/he_die2.wav"
#define HOUNDEYE_DIE_SOUND3			"houndeye/he_die3.wav"

#define HOUNDEYE_ATTACK_SOUND1		"houndeye/he_attack1.wav"
#define HOUNDEYE_ATTACK_SOUND2		"houndeye/he_attack3.wav"

#define HOUNDEYE_BLAST_SOUND1		"houndeye/he_blast1.wav"
#define HOUNDEYE_BLAST_SOUND2		"houndeye/he_blast2.wav"
#define HOUNDEYE_BLAST_SOUND3		"houndeye/he_blast3.wav"

#define HOUNDEYE_HEALTH				Skill_GetValue("sk_houndeye_health", 20) + 15
#define HOUNDEYE_DMG_BLAST			Skill_GetValue("sk_houndeye_dmg_blast", 15)
#define HOUNDEYE_ATTACK_RADIUS		384		// sonic blast radius
#define HOUNDEYE_ATTACK_RANGE		192	// range at which it decides to attack (half blast radius)

#define HOUNDEYE_ANIMATION_IDLE		0
#define HOUNDEYE_ANIMATION_RUN		3
#define HOUNDEYE_ANIMATION_ATTACK	10
#define HOUNDEYE_ANIMATION_PAIN		12
#define HOUNDEYE_ANIMATION_DIE		6

void Houndeye_IdleSound()
{
	if (self.spawnflags & SF_MONSTER_GAG) return;
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100, HOUNDEYE_IDLE_SOUND1, HOUNDEYE_IDLE_SOUND2, HOUNDEYE_IDLE_SOUND3);
}

void Houndeye_AlertSound()
{
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100, HOUNDEYE_ALERT_SOUND1, HOUNDEYE_ALERT_SOUND2, HOUNDEYE_ALERT_SOUND3);
}

void Houndeye_HuntSound()
{
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100, HOUNDEYE_HUNT_SOUND1, HOUNDEYE_HUNT_SOUND2, HOUNDEYE_HUNT_SOUND3);
}

void Houndeye_PainSound()
{
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100, HOUNDEYE_PAIN_SOUND1, HOUNDEYE_PAIN_SOUND2, HOUNDEYE_PAIN_SOUND3);
}

void Houndeye_DieSound()
{
	Sound_Stop(self, CHAN_WEAPON);
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100, HOUNDEYE_DIE_SOUND1, HOUNDEYE_DIE_SOUND2, HOUNDEYE_DIE_SOUND3);
}

void Houndeye_Stand()
{
	if (Monster_YieldToCine(Houndeye_Stand)) return;
	self.frame = HOUNDEYE_ANIMATION_IDLE;
	self.think = Houndeye_Stand;
	self.nextthink = time + 0.1;
	AI_Stand();
	if (random() > 0.95) Houndeye_IdleSound();
}

void Houndeye_Walk()
{
	if (Monster_YieldToCine(Houndeye_Walk)) return;
	self.frame = HOUNDEYE_ANIMATION_RUN;
	self.think = Houndeye_Walk;
	self.nextthink = time + 0.1;
	AI_Walk(8);
	if (random() > 0.95) Houndeye_IdleSound();
}

void Houndeye_Run()
{
	if (Monster_YieldToCine(Houndeye_Run)) return;
	self.frame = HOUNDEYE_ANIMATION_RUN;
	self.think = Houndeye_Run;
	self.nextthink = time + 0.1;
	AI_Run(18);
	if (random() > 0.95) Houndeye_HuntSound();
}

#define HOUNDEYE_WAVE_TIME  0.4

void Houndeye_SpawnShockwave(vector org)
{
	string cmd = sprintf("shockwave %g %g %g %g %g\n",
		org_x, org_y, org_z, HOUNDEYE_ATTACK_RADIUS, HOUNDEYE_WAVE_TIME);
	entity p = find(world, classname, "player");
	while (p)
	{
		stuffcmd(p, cmd);
		p = find(p, classname, "player");
	}
}

// Damages everything in a sphere, with damage falling off linearly with distance. Doesn't hurt other houndeyes.
void Houndeye_SonicAttack()
{
	Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, 100, HOUNDEYE_BLAST_SOUND1, HOUNDEYE_BLAST_SOUND2, HOUNDEYE_BLAST_SOUND3);
	// Blue energy flash at the body + expanding ground ring.
	pointparticles(particleeffectnum("zc_flash_blue_400"), self.origin + '0 0 16', '0 0 1', 1);
	Houndeye_SpawnShockwave(self.origin + '0 0 4');
	entity head = findradius(self.origin, HOUNDEYE_ATTACK_RADIUS);
	while (head)
	{
		if (head != self && head.takedamage && head.classname != "monster_houndeye")
		{
			float flDist = vlen(GetCenter(head) - self.origin);
			float flDamage = HOUNDEYE_DMG_BLAST - (flDist / HOUNDEYE_ATTACK_RADIUS) * HOUNDEYE_DMG_BLAST;

			// Half damage if target is not visible (behind cover)
			traceline(self.origin + '0 0 16', GetCenter(head), TRUE, self);
			if (trace_fraction < 1.0)
			{
				if (head.flags & FL_CLIENT)
					flDamage *= 0.5;	// players still take half through walls
				else
					flDamage = 0;		// monsters take nothing through walls
			}

			if (flDamage > 0)
				T_Damage(head, self, self, flDamage, DMG_SONIC);
		}
		head = head.chain;
	}
}

void Houndeye_AttackThink()
{
	self.timer = self.timer + 1;
	AI_Face();

	// Warm-up sound at start, plus angry bark anim events
	if (self.timer == 1)
	{
		Sound_Play(self, CHAN_WEAPON, 0.7, ATTN_NORM, 100, HOUNDEYE_ATTACK_SOUND1, HOUNDEYE_ATTACK_SOUND2);
		if (random() < 0.3)
			Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100, HOUNDEYE_ANGER_SOUND1, HOUNDEYE_ANGER_SOUND2);
	}

	// Blast on the thump frame
	if (self.timer == 8)
		Houndeye_SonicAttack();

	// Return to chasing after the attack finishes
	if (self.timer > 12)
	{
		self.think = Houndeye_Run;
		self.nextthink = time + 0.1;
		return;
	}

	self.think = Houndeye_AttackThink;
	self.nextthink = time + 0.1;
}

void Houndeye_Attack()
{
	self.timer = 0;
	self.frame = HOUNDEYE_ANIMATION_ATTACK;
	AI_Face();
	Houndeye_AttackThink();
}

// radius and roughly facing the enemy (dot >= 0.3), matching
// CheckRangeAttack1
float Houndeye_CheckAttack()
{
	if (!self.enemy) return FALSE;
	if (!(self.flags & FL_ONGROUND)) return FALSE;
	if (time < self.attack_finished) return FALSE;

	traceline(self.origin + self.view_ofs, self.enemy.origin + self.enemy.view_ofs, FALSE, self);
	if (trace_ent != self.enemy) return FALSE;

	float flDist = vlen(self.enemy.origin - self.origin);
	vector dir = normalize(self.enemy.origin - self.origin);
	makevectors(self.angles);
	float flDot = dir * v_forward;

	if (flDist <= HOUNDEYE_ATTACK_RANGE && flDot >= 0.3)
	{
		Houndeye_Attack();
		self.attack_finished = time + 2;
		return TRUE;
	}

	return FALSE;
}

// Pain
void Houndeye_Pain(entity attacker, float damage)
{
	if (self.pain_finished > time) return;
	self.pain_finished = time + 1;
	Houndeye_PainSound();
	self.frame = HOUNDEYE_ANIMATION_PAIN;
	self.think = Houndeye_Run;
	self.nextthink = time + 0.5;
}

// Death
void Houndeye_Die()
{
	if (Gib_ShouldGib())
	{
		Gib();
		return;
	}

	Houndeye_DieSound();
	self.frame = HOUNDEYE_ANIMATION_DIE;
	self.solid = SOLID_CORPSE;
	setsize(self, '-16 -16 0', '16 16 12');
	self.think = SUB_Remove;
	self.nextthink = time + 120;
}

// Precache
void Houndeye_Precache()
{
	precache_model(HOUNDEYE_MODEL);

	precache_sound(HOUNDEYE_IDLE_SOUND1);
	precache_sound(HOUNDEYE_IDLE_SOUND2);
	precache_sound(HOUNDEYE_IDLE_SOUND3);

	precache_sound(HOUNDEYE_ALERT_SOUND1);
	precache_sound(HOUNDEYE_ALERT_SOUND2);
	precache_sound(HOUNDEYE_ALERT_SOUND3);

	precache_sound(HOUNDEYE_HUNT_SOUND1);
	precache_sound(HOUNDEYE_HUNT_SOUND2);
	precache_sound(HOUNDEYE_HUNT_SOUND3);

	precache_sound(HOUNDEYE_PAIN_SOUND1);
	precache_sound(HOUNDEYE_PAIN_SOUND2);
	precache_sound(HOUNDEYE_PAIN_SOUND3);
	precache_sound(HOUNDEYE_ANGER_SOUND2);	// ANGER_SOUND1 == PAIN_SOUND1

	precache_sound(HOUNDEYE_DIE_SOUND1);
	precache_sound(HOUNDEYE_DIE_SOUND2);
	precache_sound(HOUNDEYE_DIE_SOUND3);

	precache_sound(HOUNDEYE_ATTACK_SOUND1);
	precache_sound(HOUNDEYE_ATTACK_SOUND2);

	precache_sound(HOUNDEYE_BLAST_SOUND1);
	precache_sound(HOUNDEYE_BLAST_SOUND2);
	precache_sound(HOUNDEYE_BLAST_SOUND3);
}

// Spawn
void monster_houndeye()
{
	if (Monster_RemoveIfSpent()) return;
	if(RemoveInDeathmatch()) return;

	Houndeye_Precache();
	self.solid			= SOLID_SLIDEBOX;
	self.movetype		= MOVETYPE_STEP;
	self.yaw_speed		= 20;
	self.health			= HOUNDEYE_HEALTH;
	self.view_ofs		= '0 0 20';
	self.monster_state	= MONSTERSTATE_NONE;
	setmodel(self, HOUNDEYE_MODEL);
	setsize(self, '-16 -16 0', '16 16 36');

	self.th_stand		= Houndeye_Stand;
	self.th_walk		= Houndeye_Walk;
	self.th_run			= Houndeye_Run;
	self.th_pain		= Houndeye_Pain;
	self.th_die			= Houndeye_Die;
	self.sightSound		= Houndeye_AlertSound;
	self.checkAttack	= Houndeye_CheckAttack;
	self.goalentity		= world;
	self.enemy			= world;
	Monster_InitTakeDamage();
	WalkMonster_Start();
}
