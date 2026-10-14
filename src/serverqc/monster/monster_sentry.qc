// spawnflags: shared turret bits only
// SF_MONSTER_TURRET_AUTOACTIVATE = 32
// SF_MONSTER_TURRET_STARTINACTIVE = 64
// AI/anim/dispatch reuse monster_miniturret.qc via shared think/fire/move
// functions. Field overrides set on spawn select sentry-specific dimensions.

#define SENTRY_MODEL    "models/sentry.iqm"
#define SENTRY_HEALTH   Skill_GetValue("sk_sentry_health", 40)
#define SENTRY_RANGE    (100 * 12)
#define SENTRY_DAMAGE   Skill_GetValue("sk_9mm_bullet", 5)
#define SENTRY_RETRACT  64
#define SENTRY_VIEW_Z   48
#define SENTRY_MINPITCH -60

void Sentry_Touch()
{
	// Any flesh impact wakes self.
	if (other && (other.flags & (FL_CLIENT | FL_MONSTER)))
	{
		if (!self.cnt && !self.deadflag)
		{
			self.oldenemy = other;
			self.think = MiniTurret_Deploy;
			self.nextthink = time + MINITURRET_THINK_RATE;
		}
	}
}

float Sentry_TakeDamage(entity inflictor, entity attacker, float damage, float dmgType)
{
	if (self.deadflag) return 0;

	if (!self.cnt)
	{
		// Wake up: queue Deploy, latch attacker as oldenemy for the deploy callback.
		self.oldenemy = attacker;
		if (self.think != MiniTurret_Deploy)
		{
			self.think = MiniTurret_Deploy;
			self.nextthink = time + MINITURRET_THINK_RATE;
		}
	}

	// sentry takes full damage even when retracted (no 0.1x reduction).
	return Monster_TakeDamage(inflictor, attacker, damage, dmgType);
}

void Sentry_DeathThink()
{
	self.state = MINITURRET_STATE_DEAD;
	self.nextthink = time + MINITURRET_THINK_RATE;

	if (self.deadflag != DEAD_DEAD)
	{
		self.deadflag    = DEAD_DEAD;
		self.solid       = SOLID_NOT;
		self.movetype    = MOVETYPE_TOSS;
		self.enemy       = world;
		self.cnt         = 0;
		self.dmg         = 0;
		self.pain_finished = time + 5;
		self.frame       = MINITURRET_ANIM_DIE;

		Sound_Play(self, CHAN_BODY, 1, ATTN_NORM, 100, MINITURRET_DIE_SOUND1, MINITURRET_DIE_SOUND2, MINITURRET_DIE_SOUND3);

		// Topple: random 0/120/240 degree yaw kick.
		self.angles_y    = Math_AngleMod(self.angles_y + Math_RandomInt(0, 2) * 120);
		self.angles_x    = 30;   // tip forward
	}

	if (random() < 0.35)
		te_spark(self.origin + [random(-8, 8), random(-8, 8), random(0, 20)], randomvec(), Math_RandomInt(3, 8));

	if (time >= self.pain_finished)
	{
		self.think = SUB_Null;
		self.nextthink = 0;
	}
}

void Sentry_Die()
{
	MiniTurret_DisarmOnDeath();
	self.think = Sentry_DeathThink;
	self.nextthink = time + MINITURRET_THINK_RATE;
}

void monster_sentry()
{
	if (Monster_RemoveIfSpent()) return;
	if (RemoveInDeathmatch()) return;

	MiniTurret_Precache();
	precache_model(SENTRY_MODEL);

	self.classname  = "monster_sentry";
	setmodel(self, SENTRY_MODEL);

	// Sentry-specific dimensions before SetRetiredBounds reads them.
	self.turret_range    = SENTRY_RANGE;
	self.turret_damage   = SENTRY_DAMAGE;
	self.turret_minPitch = SENTRY_MINPITCH;
	self.turret_halfWidth = 16;
	self.turret_retractZ = SENTRY_RETRACT;
	self.turret_deployZ  = SENTRY_RETRACT;   // sentry: deploy == retract
	self.turret_viewZ    = SENTRY_VIEW_Z;
	self.turret_noDisplayPitch = 1;   // keep tripod base level; yaw-only render

	MiniTurret_SetRetiredBounds();

	self.solid       = SOLID_SLIDEBOX;
	self.movetype    = MOVETYPE_NONE;
	self.health      = SENTRY_HEALTH;
	self.max_health  = self.health;
	self.view_ofs    = [0, 0, SENTRY_VIEW_Z];
	self.deadflag    = DEAD_NO;
	self.flags       = self.flags | FL_MONSTER;
	self.takedamage  = DAMAGE_AIM;
	self.takeDmgFn   = Sentry_TakeDamage;
	self.th_die      = Sentry_Die;
	self.use         = MiniTurret_Use;
	self.usehl       = MiniTurret_UseHL;
	self.touch       = Sentry_Touch;
	self.monster_bloodColor = -1;   // DONT_BLEED: machines spark, never bleed

	self.cnt   = 0;
	self.dmg   = 0;
	self.state = MINITURRET_STATE_OFF;
	self.count = ((self.spawnflags & SF_MONSTER_TURRET_AUTOACTIVATE)
		&& !(self.spawnflags & SF_MONSTER_TURRET_STARTINACTIVE));
	self.speed = self.turnrate ? self.turnrate : MINITURRET_TURNRATE;
	self.yaw_speed = self.speed;
	// Sentry never auto-retires: huge wait timeout.
	self.wait  = 1000000;

	self.ideal_yaw = Math_AngleMod(self.angles_y);

	if (self.orientation == 1)
		self.view_ofs_z = -SENTRY_VIEW_Z;

	self.v_angle    = [0, self.ideal_yaw, 0];
	self.finalangle = self.v_angle;
	self.pausetime  = time + 1;
	self.oldenemy   = world;
	self.enemy      = world;

	MiniTurret_UpdateDisplayAngles();
	setorigin(self, self.origin);

	if (self.count)
		MiniTurret_BeginAutoSearch();
	else
	{
		self.think = SUB_Null;
		self.nextthink = 0;
	}

	total_monsters = total_monsters + 1;
}
