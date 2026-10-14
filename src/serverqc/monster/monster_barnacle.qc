
#define BARNACLE_MODEL				"models/barnacle.iqm"

#define BARNACLE_ALERT_SOUND		"barnacle/bcl_alert2.wav"
#define BARNACLE_BITE_SOUND			"barnacle/bcl_bite3.wav"
#define BARNACLE_CHEW_SOUND1		"barnacle/bcl_chew1.wav"
#define BARNACLE_CHEW_SOUND2		"barnacle/bcl_chew2.wav"
#define BARNACLE_CHEW_SOUND3		"barnacle/bcl_chew3.wav"
#define BARNACLE_DIE_SOUND1			"barnacle/bcl_die1.wav"
#define BARNACLE_DIE_SOUND2			"barnacle/bcl_die3.wav"

#define BARNACLE_HEALTH				25
#define BARNACLE_BODY_HEIGHT		44
#define BARNACLE_PULL_SPEED			8		// units per tick to reel in prey
#define BARNACLE_TONGUE_RANGE		2048	// max tongue length
#define BARNACLE_GRAB_RADIUS		16		// how wide the tongue check is
#define BARNACLE_BITE_DAMAGE		100		// periodic bite damage
#define BARNACLE_KILL_TIME			10		// seconds after grab to kill victim
#define BARNACLE_THINK_RATE			0.1

#define BARNACLE_ANIMATION_IDLE		0
#define BARNACLE_ANIMATION_PAIN		3
#define BARNACLE_ANIMATION_ATTACK	4
#define BARNACLE_ANIMATION_DIE		6

// Per-entity fields
.float   barnacle_tongueLen;		// current tongue length (distance to tip)
.float   barnacle_lifting;			// TRUE while reeling in prey
.float   barnacle_killAt;			// time to deliver killing bite

entity Barnacle_TongueTouchEnt()
{
	// Trace straight down to find floor/architecture
	traceline(self.origin, self.origin - '0 0 1' * BARNACLE_TONGUE_RANGE, TRUE, self);
	self.barnacle_tongueLen = fabs(self.origin_z - trace_endpos_z);

	// Check for entities in a narrow column below us
	entity e = findradius(self.origin, self.barnacle_tongueLen + 32);
	while (e)
	{
		if (e != self && (e.flags & (FL_CLIENT | FL_MONSTER)) && IsAlive(e) && !(e.monster_barnacleEnt && e.monster_barnacleEnt != world))
		{
			// Must be roughly under us (within grab radius) and below us
			if (fabs(e.origin_x - self.origin_x) < BARNACLE_GRAB_RADIUS &&
				fabs(e.origin_y - self.origin_y) < BARNACLE_GRAB_RADIUS &&
				e.origin_z < self.origin_z)
			{
				// Must be within tongue length
				float dz = self.origin_z - e.origin_z;
				if (dz <= self.barnacle_tongueLen)
					return e;
			}
		}
		e = e.chain;
	}
	return world;
}

void Barnacle_Think()
{
	self.nextthink = time + BARNACLE_THINK_RATE;

	// Draw the tongue visual every tick
	vector tongueEnd = self.origin - '0 0 1' * self.barnacle_tongueLen;
	if (self.enemy) tongueEnd = self.enemy.origin + '0 0 1' * self.enemy.view_ofs_z;
	DrawLine(self.origin, tongueEnd, "models/barnacle_tounge.md3", 64, 2, BARNACLE_THINK_RATE);
	if (self.enemy)
	{
		entity prey = self.enemy;
		if (!IsAlive(prey))
		{
			prey.movetype = MOVETYPE_STEP;
			prey.velocity = '0 0 0';
			Monster_BarnacleRelease(prey);
			self.enemy = world;
			self.barnacle_lifting = FALSE;
			self.frame = BARNACLE_ANIMATION_IDLE;
			return;
		}

		if (self.barnacle_lifting)
		{
			if (self.enemy && !IsAlive(self.enemy))
			{
				self.enemy = world;
				self.barnacle_lifting = FALSE;
				return;
			}
			
			self.enemy.movetype = MOVETYPE_NONE;

			vector vecNewEnemyOrigin = self.enemy.origin;
			vecNewEnemyOrigin_x = self.origin_x;
			vecNewEnemyOrigin_y = self.origin_y;

			vecNewEnemyOrigin_x -= 6 * cos(self.enemy.angles_y * M_PI / 180.0);	
			vecNewEnemyOrigin_y -= 6 * sin(self.enemy.angles_y * M_PI / 180.0);

			vecNewEnemyOrigin_z += BARNACLE_PULL_SPEED;

			if (fabs(self.origin.z - (vecNewEnemyOrigin.z + self.enemy.view_ofs_z - 8)) < BARNACLE_BODY_HEIGHT)
			{
				self.barnacle_lifting = FALSE;
				self.enemy.monster_barnacleLifting = FALSE;
				Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, "barnacle/bcl_bite3.wav");
				self.barnacle_killAt = time + 10;
				self.attack_finished = self.attack_finished + .4;
				
			}

			setorigin (self.enemy, vecNewEnemyOrigin);
					}
		else
		{
			setorigin(prey, self.origin - [0, 0, prey.size_z] - [0, 0, self.size_z /2]);
			prey.movetype = MOVETYPE_NONE;

			// Kill after the timer expires
			if (self.barnacle_killAt > 0 && time > self.barnacle_killAt)
			{
				T_Damage(prey, self, self, prey.health + 50);
				Monster_BarnacleRelease(prey);
				self.enemy = world;
				self.frame = BARNACLE_ANIMATION_IDLE;
				return;
			}

			// Random chewing sounds
			if (random() < 0.02)
			{
				Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, 100, BARNACLE_CHEW_SOUND1, BARNACLE_CHEW_SOUND2, BARNACLE_CHEW_SOUND3);
			}
			if(self.attack_finished < time)
			{
				float dmg = BARNACLE_BITE_DAMAGE;
				if (prey.health <= dmg) dmg = prey.health + 50;
				T_Damage(prey, self, self, dmg);
				self.attack_finished = self.attack_finished + .75;
				self.frame = BARNACLE_ANIMATION_ATTACK;
			}
		}
	}
	else
	{
		entity touched = Barnacle_TongueTouchEnt();
		if(touched == world) return;

		// Grab!
		Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, BARNACLE_ALERT_SOUND);
		self.frame = BARNACLE_ANIMATION_ATTACK;

		self.enemy = touched;
		self.barnacle_lifting = TRUE;
		self.barnacle_killAt = -1;
		Monster_BarnacleGrab(touched, self);

		// Lock the prey in place
		if (touched.flags & FL_ONGROUND) touched.flags = touched.flags - FL_ONGROUND;
		touched.velocity = '0 0 -20';
	}
}


void Barnacle_Pain(entity attacker, float damage)
{
	self.frame = BARNACLE_ANIMATION_PAIN;
}

void Barnacle_Die()
{
	// Release any grabbed prey
	if (self.enemy)
	{
		self.enemy.movetype = MOVETYPE_STEP;
		if(self.enemy.flags & FL_CLIENT) self.enemy.movetype = MOVETYPE_WALK;
		self.enemy.velocity = '0 0 0';
		Monster_BarnacleRelease(self.enemy);
	}

	Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, 100, BARNACLE_DIE_SOUND1, BARNACLE_DIE_SOUND2);

	self.frame = BARNACLE_ANIMATION_DIE;
	self.solid = SOLID_NOT;
	self.takedamage = DAMAGE_NO;
	self.think = SUB_Remove;
	self.nextthink = time + 120;
}

void Barnacle_Precache()
{
	precache_model(BARNACLE_MODEL);
	precache_model("models/barnacle_tounge.md3");   // tongue beam (Barnacle_Think DrawLine)

	precache_sound(BARNACLE_ALERT_SOUND);
	precache_sound(BARNACLE_BITE_SOUND);
	precache_sound(BARNACLE_CHEW_SOUND1);
	precache_sound(BARNACLE_CHEW_SOUND2);
	precache_sound(BARNACLE_CHEW_SOUND3);
	precache_sound(BARNACLE_DIE_SOUND1);
	precache_sound(BARNACLE_DIE_SOUND2);
}

void monster_barnacle()
{
	if (Monster_RemoveIfSpent()) return;
	if(RemoveInDeathmatch()) return;

	Barnacle_Precache();
	self.solid			= SOLID_SLIDEBOX;
	self.movetype		= MOVETYPE_NONE;
	self.takedamage		= DAMAGE_AIM;
	self.health			= BARNACLE_HEALTH;
	self.view_ofs		= '0 0 -16';
	setmodel(self, BARNACLE_MODEL);
	setsize(self, '-16 -16 -32', '16 16 0');

	self.flags			= self.flags | FL_MONSTER;
	self.enemy	= world;
	self.barnacle_lifting = FALSE;

	self.th_pain		= Barnacle_Pain;
	self.th_die			= Barnacle_Die;

	Monster_InitTakeDamage();

	// Initial tongue trace to find floor distance
	traceline(self.origin, self.origin - '0 0 1' * BARNACLE_TONGUE_RANGE, TRUE, self);
	self.barnacle_tongueLen = fabs(self.origin_z - trace_endpos_z);

	self.think			= Barnacle_Think;
	self.nextthink		= time + 0.5;
}
