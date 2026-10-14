
#define	ZOMBIE_AE_ATTACK_RIGHT		0x01
#define	ZOMBIE_AE_ATTACK_LEFT		0x02
#define	ZOMBIE_AE_ATTACK_BOTH		0x03

#define ZOMBIE_FLINCH_DELAY			2

#define ZOMBIE_MODEL 				"models/zombie.iqm"
#define ZOMBIE_ATTACK_HIT_SOUND1	"zombie/claw_strike1.wav"
#define ZOMBIE_ATTACK_HIT_SOUND2	"zombie/claw_strike2.wav"
#define ZOMBIE_ATTACK_HIT_SOUND3	"zombie/claw_strike3.wav"

#define ZOMBIE_ATTACK_MISS_SOUND1	"zombie/claw_miss1.wav"
#define ZOMBIE_ATTACK_MISS_SOUND2	"zombie/claw_miss2.wav"

#define ZOMBIE_ATTACK_SOUND1		"zombie/zo_attack1.wav"
#define ZOMBIE_ATTACK_SOUND2		"zombie/zo_attack2.wav"

#define ZOMBIE_IDLE_SOUND1			"zombie/zo_idle1.wav"
#define ZOMBIE_IDLE_SOUND2			"zombie/zo_idle2.wav"
#define ZOMBIE_IDLE_SOUND3			"zombie/zo_idle3.wav"
#define ZOMBIE_IDLE_SOUND4			"zombie/zo_idle4.wav"

#define ZOMBIE_ALERT_SOUND1			"zombie/zo_alert10.wav"
#define ZOMBIE_ALERT_SOUND2			"zombie/zo_alert20.wav"
#define ZOMBIE_ALERT_SOUND3			"zombie/zo_alert30.wav"

#define ZOMBIE_PAIN_SOUND1			"zombie/zo_pain1.wav"
#define ZOMBIE_PAIN_SOUND2			"zombie/zo_pain2.wav"

#define ZOMBIE_HEALTH				Skill_GetValue("sk_zombie_health", 50)
#define ZOMBIE_FOV					0.5

// Damage values
#define ZOMBIE_DMG_ONE_SLASH		Skill_GetValue("sk_zombie_dmg_one_slash", 20)
#define ZOMBIE_DMG_BOTH_SLASH		Skill_GetValue("sk_zombie_dmg_both_slash", 40)


float AttackHumans()
{
	entity e = FindNearest("monster_grunt", self.origin);
	if(e)
	{
		if(IsVisible(e))
		{
			self.enemy = e;
			FoundTarget();
			return TRUE;
		}
	}
	return FALSE;
};

// SetYawSpeed: allows different turn rates
void Zombie_SetYawSpeed()
{
	self.yaw_speed = YAW_HL(120);	// SetYawSpeed
}

void Zombie_PainSound()
{
	int pitch = 95 + Math_RandomInt(0, 9);

	if (Math_RandomInt(0,5) < 2)
		Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, pitch, ZOMBIE_PAIN_SOUND1, ZOMBIE_PAIN_SOUND2);
}

float Zombie_TakeDamage(entity pevInflictor, entity pevAttacker, float flDamage, int bitsDamageType)
{
	if (bitsDamageType == DMG_BULLET)
	{
		vector vecDir = self.origin - (pevInflictor.absmin + pevInflictor.absmax) * 0.5;
		vecDir = normalize(vecDir);
		float flForce = Combat_DamageForce(flDamage);
		self.velocity = self.velocity + vecDir * flForce;
		flDamage *= 0.3;
	}

	// Temporary fix
	if (IsAlive(self)) Zombie_PainSound();
	Combat_TakeDamage(self, pevInflictor, pevAttacker, flDamage, bitsDamageType);
	return TRUE;
}


void Zombie_AlertSound()
{
	float pitch = 95 + Math_RandomInt(0,9);
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, pitch, ZOMBIE_ALERT_SOUND1, ZOMBIE_ALERT_SOUND2, ZOMBIE_ALERT_SOUND3);
}

void Zombie_IdleSound()
{
	if (self.spawnflags & SF_MONSTER_GAG) return;
	float pitch = 95 + Math_RandomInt(0,9);
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, pitch, ZOMBIE_IDLE_SOUND1, ZOMBIE_IDLE_SOUND2, ZOMBIE_IDLE_SOUND3, ZOMBIE_IDLE_SOUND4);
}

void Zombie_AttackSound()
{
	float pitch = 95 + Math_RandomInt(0,9);
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, pitch, ZOMBIE_ATTACK_SOUND1, ZOMBIE_ATTACK_SOUND2);
}


void Zombie_Stand()
{
	if (Monster_YieldIfDead()) return;
	if (Monster_YieldToCine(Zombie_Stand)) return;
	self.frame = 0;
	self.think = Zombie_Stand;
	self.nextthink = time + 0.1;
	AI_Stand();
	if(random() > 0.9) Zombie_IdleSound();
}

void Zombie_Walk()
{
	if (Monster_YieldIfDead()) return;
	if (Monster_YieldToCine(Zombie_Walk)) return;
	self.frame = 10;
	self.think = Zombie_Walk;
	self.nextthink = time + 0.1;
	AI_Walk(7);
	if(random() > 0.9) Zombie_IdleSound();
}

void Zombie_Run()
{
	if (Monster_YieldIfDead()) return;
	if (Monster_YieldToCine(Zombie_Run)) return;
	self.frame = 10;
	self.think = Zombie_Run;
	self.nextthink = time + 0.1;
	AI_Run(7);
	if(random() > 0.9) Zombie_IdleSound();
}

//ATTACK

void Zombie_Swing(float direction = 0)
{
	makevectors(self.angles);
	entity pHurt = Combat_CheckTraceHullAttack(70, ZOMBIE_DMG_ONE_SLASH, DMG_SLASH);
	if (pHurt)
	{
		if (pHurt.flags & (FL_MONSTER|FL_CLIENT))
		{
			pHurt.punchangle_x = 5;
			if(direction == 1) //right
			{
				pHurt.punchangle_z = -18;
				pHurt.velocity = pHurt.velocity - v_right * 100;
			}
			else if(direction == 2) //left
			{
				pHurt.punchangle_z = 18;
				pHurt.velocity = pHurt.velocity + v_right * 100;
			}
			else
			{
				pHurt.velocity = pHurt.velocity + v_forward * -100;
			}

		}
		Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, 100 + Math_RandomInt(-5,5), ZOMBIE_ATTACK_HIT_SOUND1, ZOMBIE_ATTACK_HIT_SOUND2, ZOMBIE_ATTACK_HIT_SOUND3);
	}
	else Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, 100 + Math_RandomInt(-5,5), ZOMBIE_ATTACK_MISS_SOUND1, ZOMBIE_ATTACK_MISS_SOUND2);

	if (random() > 0.5) Zombie_AttackSound();
}

void Zombie_Attack1()
{
	if (Monster_YieldToCine(Zombie_Run)) return;   // drop the interrupted swing
	if(self.frame != 8)
	{
		self.frame = 8;
		self.think = Zombie_Attack1;
	}
	
	AI_Face();
	self.timer = self.timer + 1;
	if(self.timer == 4) Zombie_Swing(1);
	if(self.timer == 12) Zombie_Swing(2);

	if(self.timer > 24) self.think = Zombie_Run;
	else self.think = Zombie_Attack1;
	self.nextthink = time + 0.1;
}

void Zombie_Attack2()
{
	if (Monster_YieldToCine(Zombie_Run)) return;   // drop the interrupted swing
	if(self.frame != 9)
	{
		self.frame = 9;
		self.think = Zombie_Attack2;
	}
	
	AI_Face();
	self.timer = self.timer + 1;
	if(self.timer == 3) Zombie_Swing(0);
	if(self.timer > 14) self.think = Zombie_Run;
	else self.think = Zombie_Attack2;
	self.nextthink = time + 0.1;
}

void Zombie_Attack()
{
	self.timer = 0;
	AI_Charge(20);
	Zombie_AttackSound();
	if(random() >= 0.5) Zombie_Attack1();
	else Zombie_Attack2();
}


void Zombie_PainFlinch()
{
	self.frame = 4;
	AI_PainForward(1);
	self.nextthink = time + 1;
	self.think = Zombie_Run;
}

void Zombie_Pain(entity attacker, float damage)
{
	if (self.monster_cine && self.monster_cine != world) return;   // scripted sequence owns us
	if(random() > 0.6) return;
	if (self.pain_finished > time) return;
	self.pain_finished = time + 4;
	Zombie_PainFlinch();
}


void Zombie_DieHeadshot1()
{
	self.frame = 15;
}

void Zombie_DieHeadshot2()
{
	self.frame = 16;
}

void Zombie_Die1()
{
	self.frame = 17;
}

void Zombie_Die2()
{
	self.frame = 18;
}

void Zombie_Die()
{
	Monster_ExitScriptedSequence();

	if (self.health < -40)
	{
		Gib();
		return;
	}

	setsize(self, '-15 -15 0', '15 15 12');
	self.solid = SOLID_CORPSE;
	self.flags = self.flags - (self.flags & FL_MONSTER);
	self.deadflag = DEAD_DEAD;
	self.takedamage = DAMAGE_NO;
	self.enemy = world;
	self.think = SUB_Remove;
	self.nextthink = time + 120;
	if(self.hitbox == HITBOX_HEAD)
	{
		if(random() > 0.5) Zombie_DieHeadshot1();
		else Zombie_DieHeadshot2();
	}
	else
	{
		if(random() > 0.5) Zombie_Die1();
		else Zombie_Die2();
	}
}


void Zombie_Precache()
{
	precache_model(ZOMBIE_MODEL);
	precache_sound(ZOMBIE_ATTACK_HIT_SOUND1);
	precache_sound(ZOMBIE_ATTACK_HIT_SOUND2);
	precache_sound(ZOMBIE_ATTACK_HIT_SOUND3);

	precache_sound(ZOMBIE_ATTACK_MISS_SOUND1);
	precache_sound(ZOMBIE_ATTACK_MISS_SOUND2);

	precache_sound(ZOMBIE_ATTACK_SOUND1);
	precache_sound(ZOMBIE_ATTACK_SOUND2);

	precache_sound(ZOMBIE_IDLE_SOUND1);
	precache_sound(ZOMBIE_IDLE_SOUND2);
	precache_sound(ZOMBIE_IDLE_SOUND3);
	precache_sound(ZOMBIE_IDLE_SOUND4);

	precache_sound(ZOMBIE_ALERT_SOUND1);
	precache_sound(ZOMBIE_ALERT_SOUND2);
	precache_sound(ZOMBIE_ALERT_SOUND3);

	precache_sound(ZOMBIE_PAIN_SOUND1);
	precache_sound(ZOMBIE_PAIN_SOUND2);

}


void monster_zombie()
{
	if (Monster_RemoveIfSpent()) return;
	if(RemoveInDeathmatch()) return;

	// spawnflag 1: crucified (wall-attached) zombie; not supported
	if (self.spawnflags & 1)
	{
		remove(self);
		return;
	}

	Zombie_Precache();
	self.solid 			= SOLID_SLIDEBOX;
	self.movetype 		= MOVETYPE_STEP;
	self.yaw_speed 		= 10;
	self.health			= ZOMBIE_HEALTH; 		//100 in hard
	self.view_ofs		= VEC_VIEW;
	self.monster_state	= MONSTERSTATE_NONE;
	self.monster_capability	= BITS_CAP_DOORS_GROUP;
	setmodel(self, ZOMBIE_MODEL);
	setsize(self, VEC_HUMAN_HULL_MIN, VEC_HUMAN_HULL_MAX);
	
	self.th_stand = Zombie_Stand;
	self.th_walk = Zombie_Walk;
	self.th_run = Zombie_Run;
	self.th_melee = Zombie_Attack;
	self.th_pain = Zombie_Pain;
	self.th_die = Zombie_Die;
	self.sightSound = Zombie_AlertSound;
	self.goalentity = world;
	self.enemy = world;
	Monster_InitTakeDamage();
	WalkMonster_Start();
};
