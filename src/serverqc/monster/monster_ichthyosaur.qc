// spawnflags must be shared (SF_MONSTER_* only)
// Anims (data/models/icky.iqm.framegroups): swim=0, attack=1, flinch=2,
//   die=3, bellyup=4. swim is the only loop; framerate scales with speed
//
// Skins (eye texture): 0=mad, 1=base, 2=closed (blink)
// back/look variants; unused by this port

#define ICKY_MODEL          "models/icky.iqm"

#define ICKY_HEALTH         Skill_GetValue("sk_ichthyosaur_health", 200)
#define ICKY_DMG_SHAKE      Skill_GetValue("sk_ichthyosaur_shake", 35)
#define ICKY_SPEED          150     // ICHTHYOSAUR_SPEED
#define ICKY_PROBE_LEN      150     // PROBE_LENGTH
#define ICKY_SIGHT_RANGE    2048
#define ICKY_THINK_RATE     0.1

#define ICKY_FR_SWIM        0
#define ICKY_FR_ATTACK      1
#define ICKY_FR_FLINCH      2
#define ICKY_FR_DIE         3
#define ICKY_FR_BELLYUP     4

#define ICKY_EYE_MAD        0
#define ICKY_EYE_BASE       1
#define ICKY_EYE_CLOSED     2

// icky_mode values (replaces schedule selection)
#define ICKY_MODE_IDLE      0
#define ICKY_MODE_CHASE     1
#define ICKY_MODE_CIRCLE    2

.vector icky_saveVel;
.float  icky_flightSpeed;
.float  icky_idealDist;     // m_idealDist
.float  icky_maxDist;
.float  icky_minSpeed;
.float  icky_maxSpeed;
.float  icky_onAttack;      // m_bOnAttack
.float  icky_enemyTouched;
.float  icky_blink;
.float  icky_nextAlert;
.float  icky_animLock;      // one-shot anim (attack/flinch) owns frame until this time
.float  icky_biteTime;      // pending bite anim-event; 0 = none
.float  icky_mode;          // ICKY_MODE_* of previous think (edge-detect for attack sound)

float icky_probeFrac;       // out-param of Icky_ProbeZ

float Icky_FrameByName(string fname)
{
	if (fname == "swim")    return ICKY_FR_SWIM;
	if (fname == "attack")  return ICKY_FR_ATTACK;
	if (fname == "flinch")  return ICKY_FR_FLINCH;
	if (fname == "die")     return ICKY_FR_DIE;
	if (fname == "bellyup") return ICKY_FR_BELLYUP;
	return -1;
}

void Icky_Precache()
{
	precache_model(ICKY_MODEL);
	precache_model(BUBBLE_SPRITE_PATH);

	precache_sound("ichy/ichy_idle1.wav");
	precache_sound("ichy/ichy_idle2.wav");
	precache_sound("ichy/ichy_idle3.wav");
	precache_sound("ichy/ichy_idle4.wav");
	precache_sound("ichy/ichy_alert2.wav");
	precache_sound("ichy/ichy_alert3.wav");
	precache_sound("ichy/ichy_attack1.wav");
	precache_sound("ichy/ichy_attack2.wav");
	precache_sound("ichy/ichy_bite1.wav");
	precache_sound("ichy/ichy_bite2.wav");
	precache_sound("ichy/ichy_pain2.wav");
	precache_sound("ichy/ichy_pain3.wav");
	precache_sound("ichy/ichy_pain5.wav");
	precache_sound("ichy/ichy_die2.wav");
	precache_sound("ichy/ichy_die4.wav");
}

// EMIT_ICKY_SOUND: vol 1.0, pitch 95-105
void Icky_IdleSound()
{
	if (self.spawnflags & SF_MONSTER_GAG) return;
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, Math_RandomInt(95, 105),
		"ichy/ichy_idle1.wav", "ichy/ichy_idle2.wav",
		"ichy/ichy_idle3.wav", "ichy/ichy_idle4.wav");
}

void Icky_AlertSound()
{
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, Math_RandomInt(95, 105),
		"ichy/ichy_alert2.wav", "ichy/ichy_alert3.wav");
}

void Icky_AttackSound()
{
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, Math_RandomInt(95, 105),
		"ichy/ichy_attack1.wav", "ichy/ichy_attack2.wav");
}

void Icky_BiteSound()
{
	Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, Math_RandomInt(95, 105),
		"ichy/ichy_bite1.wav", "ichy/ichy_bite2.wav");
}

void Icky_PainSound()
{
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, Math_RandomInt(95, 105),
		"ichy/ichy_pain2.wav", "ichy/ichy_pain3.wav", "ichy/ichy_pain5.wav");
}

void Icky_DeathSound()
{
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, Math_RandomInt(95, 105),
		"ichy/ichy_die2.wav", "ichy/ichy_die4.wav");
}

vector Icky_Cross(vector a, vector b)
{
	return [a_y * b_z - a_z * b_y,
	        a_z * b_x - a_x * b_z,
	        a_x * b_y - a_y * b_x];
}

float Icky_PointInWater(vector p)
{
	float pc = pointcontents(p);
	return (pc == CONTENT_WATER || pc == CONTENT_SLIME || pc == CONTENT_LAVA);
}

// Sets icky_probeFrac to the sampled fraction where water ends.
float Icky_ProbeZ(vector fromPos, vector probeEnd)
{
	icky_probeFrac = 1;
	if (Icky_PointInWater(probeEnd)) return FALSE;
	if (!Icky_PointInWater(fromPos)) { icky_probeFrac = 0; return TRUE; }

	for (float i = 1; i <= 8; i = i + 1)
	{
		vector p = fromPos + (probeEnd - fromPos) * (i / 8);
		if (!Icky_PointInWater(p))
		{
			icky_probeFrac = (i - 1) / 8;
			return TRUE;
		}
	}
	return TRUE;
}

vector Icky_DoProbe(vector vecProbe)
{
	vector wallNormal = '0 0 -1';   // "water surface" normal points down for fish
	float frac = 1;
	float bumped = FALSE;

	if (Icky_ProbeZ(self.origin, vecProbe))
	{
		bumped = TRUE;
		frac = icky_probeFrac;
	}

	tracebox(self.origin, self.mins, self.maxs, vecProbe, FALSE, self);
	if (trace_startsolid || trace_fraction < 0.99)
	{
		float tf = Math_Clamp(trace_fraction, 0, 1);
		if (tf < frac)
		{
			frac = tf;
			bumped = TRUE;
			wallNormal = trace_plane_normal;
		}
	}

	if (bumped && (!self.enemy || trace_ent != self.enemy))
	{
		vector probeDir = vecProbe - self.origin;
		// steer = component of wallNormal perpendicular to probeDir
		vector perp  = Icky_Cross(probeDir, wallNormal);
		vector steer = Icky_Cross(perp, probeDir);

		float force = self.icky_flightSpeed * (1 - frac)
			* (normalize(wallNormal) * normalize(self.icky_saveVel));
		if (force < 0) force = -force;

		return normalize(steer) * force;
	}
	return '0 0 0';
}

void Icky_Swim()
{
	vector start = self.origin;
	vector Angles;

	if (self.flags & FL_ONGROUND)
	{
		// Beached: kick back into the water with a random heading.
		self.angles_x = 0;
		self.angles_y = Math_AngleMod(self.angles_y + random(-45, 45));
		self.flags = self.flags - (self.flags & FL_ONGROUND);

		makevectors([-Math_SignedAngle(self.angles_x), self.angles_y, 0]);
		self.velocity = v_forward * 200 + v_up * 200;
		self.icky_saveVel = self.velocity;
		return;
	}

	if (self.icky_onAttack && self.icky_flightSpeed < self.icky_maxSpeed)
		self.icky_flightSpeed = self.icky_flightSpeed + 40;

	// Swim loop owns the frame unless a one-shot (attack/flinch) is playing.
	if (time >= self.icky_animLock)
	{
		if (self.frame != ICKY_FR_SWIM)
			Monster_PlayAnimByName(self, "swim");
		self.framerate = self.icky_flightSpeed / 150;
	}

	if (self.icky_saveVel == '0 0 0')
	{
		makevectors([0, self.angles_y, 0]);
		self.icky_saveVel = v_forward * self.icky_flightSpeed;
	}

	// Probe along the current swim direction.
	Angles = vectoangles(self.icky_saveVel);
	makevectors([-Math_SignedAngle(Angles_x), Angles_y, 0]);   // v_forward == swim dir
	vector fwd = v_forward;
	vector rgt = v_right;
	vector up  = v_up;

	vector f = Icky_DoProbe(start + fwd * ICKY_PROBE_LEN);
	vector r = Icky_DoProbe(start + fwd * (ICKY_PROBE_LEN / 3) + rgt);
	vector l = Icky_DoProbe(start + fwd * (ICKY_PROBE_LEN / 3) - rgt);
	vector u = Icky_DoProbe(start + fwd * (ICKY_PROBE_LEN / 3) + up);
	vector d = Icky_DoProbe(start + fwd * (ICKY_PROBE_LEN / 3) - up);

	vector steering = f + r + l + u + d;
	self.icky_saveVel = normalize(self.icky_saveVel + steering * 0.5);

	// Only swim fast in the direction the body already faces.
	makevectors([-Math_SignedAngle(self.angles_x), self.angles_y, 0]);
	float flDot = v_forward * self.icky_saveVel;
	if (flDot > 0.5)
		self.icky_saveVel = self.icky_saveVel * self.icky_flightSpeed;
	else if (flDot > 0)
		self.icky_saveVel = self.icky_saveVel * self.icky_flightSpeed * (flDot + 0.5);
	else
		self.icky_saveVel = self.icky_saveVel * 80;
	self.velocity = self.icky_saveVel;

	Angles = vectoangles(self.icky_saveVel);

	// Smooth pitch.
	float goalPitch = Math_SignedAngle(Angles_x);
	float pitch = Math_SignedAngle(self.angles_x);
	pitch = Math_Approach(goalPitch, pitch, 50 * 0.1);
	pitch = Math_Clamp(pitch, -80, 80);
	self.angles_x = pitch;

	// Smooth yaw; banking roll is generated from the turn rate.
	float turn = Math_AngleDistance(Angles_y, self.angles_y);
	float speed = self.icky_flightSpeed * 0.1;
	if (fabs(turn) > speed)
		turn = (turn < 0) ? -speed : speed;
	self.angles_y = Math_AngleMod(self.angles_y + turn);

	float roll = Math_SignedAngle(self.angles_z) - turn;

	// Roll smoothing back toward level (vectoangles roll is always 0).
	float rollTurn = Math_AngleDistance(0, roll);
	speed = (self.icky_flightSpeed / 2) * 0.1;
	if (fabs(rollTurn) < speed)
		roll = roll + rollTurn;
	else
		roll = roll + ((rollTurn < 0) ? -speed : speed);
	self.angles_z = Math_Clamp(roll, -20, 20);
}

void Icky_BiteEvent()
{
	if (!self.enemy || self.enemy == world) return;
	if (!IsVisible(self.enemy)) return;

	entity pHurt = self.enemy;
	vector bodyTarget = pHurt.origin + pHurt.view_ofs;

	// skip the hurt (but still bite sound + bubbles) when the
	// enemy slipped out of reach since the touch.
	if (self.icky_enemyTouched >= time - 0.2 || vlen(bodyTarget - self.origin) <= 80)
	{
		vector shootDir = normalize(bodyTarget - (self.origin + self.view_ofs));
		makevectors([-Math_SignedAngle(self.angles_x), self.angles_y, 0]);

		if (shootDir * v_forward > 0.707)
		{
			self.icky_onAttack = TRUE;
			pHurt.punchangle_z = -18;
			pHurt.punchangle_x = 5;
			pHurt.velocity = pHurt.velocity - v_right * 300;
			if (pHurt.flags & FL_CLIENT)
			{
				// Shake the victim's view around.
				pHurt.angles_x = pHurt.v_angle_x + random(-35, 35);
				pHurt.angles_y = pHurt.v_angle_y + random(-90, 90);
				pHurt.angles_z = 0;
				pHurt.fixangle = TRUE;
			}
			T_Damage(pHurt, self, self, ICKY_DMG_SHAKE, DMG_SLASH);
		}
	}
	Icky_BiteSound();

	makevectors([-Math_SignedAngle(self.angles_x), self.angles_y, 0]);
	vector src = self.origin + v_forward * 32;
	for (float i = 0; i < 6; i = i + 1)
		Bubble_Spawn(src - '8 8 8', src + '8 8 8', 0);
}

void Icky_BiteTouch()
{
	// Prime the bite when we bump who we want to eat.
	if (other == self.enemy && self.enemy != world)
	{
		self.icky_enemyTouched = time;
		self.icky_onAttack = TRUE;
	}
}

void Icky_CombatUse(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	useType = useTypeArg;               // ShouldToggle() reads this global
	if (!ShouldToggle(self.icky_onAttack)) return;

	self.icky_onAttack = !self.icky_onAttack;
	self.monster_isAsleep = FALSE;
}

entity Icky_FindTarget()
{
	if (self.spawnflags & SF_MONSTER_PRISONER) return world;

	entity p = FindNearestPlayer(self.origin);
	if (!p || !IsAlive(p)) return world;
	if (vlen(p.origin - self.origin) > ICKY_SIGHT_RANGE) return world;
	if (!IsVisible(p)) return world;

	// WAIT_TILL_SEEN: stay dormant until the player is looking at us.
	if (self.monster_isAsleep)
	{
		makevectors(p.v_angle);
		if (normalize(self.origin - (p.origin + p.view_ofs)) * v_forward < 0.5)
			return world;
		self.monster_isAsleep = FALSE;
	}
	return p;
}

void Icky_CircleEnemy()
{
	if (IsVisible(self.enemy))
	{
		vector vecFrom = self.enemy.origin + self.enemy.view_ofs;
		vector vecDelta = normalize(self.origin - vecFrom);
		vector vecSwim = normalize(Icky_Cross(vecDelta, '0 0 1'));
		if (vecSwim * self.icky_saveVel < 0)
			vecSwim = vecSwim * -1;

		vector vecPos = vecFrom + vecDelta * self.icky_idealDist + vecSwim * 32;

		tracebox(vecFrom, '-32 -32 -32', '32 32 32', vecPos, TRUE, self.enemy);
		if (trace_fraction > 0.5)
			vecPos = trace_endpos;

		self.icky_saveVel = self.icky_saveVel * 0.8
			+ normalize(vecPos - self.origin) * (0.2 * self.icky_flightSpeed);

		// keep distance while watched, dart in when the enemy looks away.
		float watched = FALSE;
		vector enemyView = (self.enemy.flags & FL_CLIENT) ? self.enemy.v_angle : self.enemy.angles;
		makevectors([0, enemyView_y, 0]);
		if (normalize(self.origin - vecFrom) * v_forward > 0.25)
		{
			traceline(vecFrom, self.origin + self.view_ofs, TRUE, self.enemy);
			if (trace_fraction == 1) watched = TRUE;
		}

		if (watched)
		{
			self.icky_nextAlert = self.icky_nextAlert - 0.1;

			if (self.icky_idealDist < self.icky_maxDist)
				self.icky_idealDist = self.icky_idealDist + 4;
			if (self.icky_flightSpeed > self.icky_minSpeed)
				self.icky_flightSpeed = self.icky_flightSpeed - 2;
			else if (self.icky_flightSpeed < self.icky_minSpeed)
				self.icky_flightSpeed = self.icky_flightSpeed + 2;
			if (self.icky_minSpeed < self.icky_maxSpeed)
				self.icky_minSpeed = self.icky_minSpeed + 0.5;
		}
		else
		{
			self.icky_nextAlert = self.icky_nextAlert + 0.1;

			if (self.icky_idealDist > 128)
				self.icky_idealDist = self.icky_idealDist - 4;
			if (self.icky_flightSpeed < self.icky_maxSpeed)
				self.icky_flightSpeed = self.icky_flightSpeed + 4;
		}
	}
	else
	{
		self.icky_nextAlert = time + 0.2;
	}

	if (self.icky_nextAlert < time)
	{
		Icky_AlertSound();
		self.icky_nextAlert = time + random(3, 5);
	}
}

void Icky_FloatThink()
{
	self.nextthink = time + ICKY_THINK_RATE;

	// TASK_ICHTHYOSAUR_FLOAT: level out and bob at the surface.
	float pitch = Math_SignedAngle(self.angles_x);
	self.angles_x = Math_Approach(0, pitch, 20);

	self.velocity = self.velocity * 0.8;
	if (Icky_PointInWater(self.origin) && self.velocity_z < 64)
		self.velocity_z = self.velocity_z + 8;
	else
		self.velocity_z = self.velocity_z - 8;
}

void Icky_DieThink()
{
	self.deadflag = DEAD_DEAD;
	self.skin = ICKY_EYE_BASE;
	Monster_PlayAnimByName(self, "bellyup");
	self.think = Icky_FloatThink;
	self.nextthink = time + ICKY_THINK_RATE;
}

void Icky_Die()
{
	Icky_DeathSound();
	self.deadflag  = DEAD_DYING;
	self.velocity  = '0 0 0';	// Killed() override
	self.solid     = SOLID_NOT;
	self.touch     = SUB_Null;
	self.icky_biteTime = 0;

	float dur = Monster_PlayAnimByName(self, "die");
	if (dur <= 0) dur = 1;
	self.think     = Icky_DieThink;
	self.nextthink = time + dur;
}

void Icky_Pain(entity attacker, float damage)
{
	Icky_PainSound();

	if (self.monster_cine && self.monster_cine != world) return;   // scripted sequence owns us

	// Back off to a wider circle; if already close, commit to the attack.
	if (self.icky_idealDist > 128)
	{
		self.icky_maxDist = 512;
		self.icky_idealDist = 512;
	}
	else
		self.icky_onAttack = TRUE;

	if (damage >= 20) self.icky_onAttack = TRUE;
	if (self.health < self.max_health - 20) self.icky_onAttack = TRUE;

	if (!self.enemy && attacker.flags & FL_CLIENT)
		self.enemy = attacker;

	if (time >= self.icky_animLock)
	{
		float dur = Monster_PlayAnimByName(self, "flinch");
		if (dur > 0) self.icky_animLock = time + dur;
	}
}

void Icky_SwimThink()
{
	self.nextthink = time + ICKY_THINK_RATE;
	if (self.health <= 0) return;

	// scripted_sequence owns frame/state
	if (self.monster_cine && self.monster_cine != world)
	{
		self.velocity = '0 0 0';
		return;
	}

	// Pending bite anim event.
	if (self.icky_biteTime && time >= self.icky_biteTime)
	{
		self.icky_biteTime = 0;
		Icky_BiteEvent();
	}

	// Validate / acquire enemy.
	if (self.enemy != world && !IsAlive(self.enemy))
	{
		self.enemy = world;
		self.icky_onAttack = FALSE;
		self.icky_flightSpeed = 80;
		self.icky_mode = ICKY_MODE_IDLE;
	}
	if (!self.enemy)
	{
		entity newEnemy = Icky_FindTarget();
		if (newEnemy != world)
		{
			self.enemy = newEnemy;
			self.monster_state = MONSTERSTATE_COMBAT;
			self.icky_maxSpeed = 400;	// GetSchedule MONSTERSTATE_COMBAT
			self.icky_flightSpeed = ICKY_SPEED;
			Icky_AlertSound();
		}
	}

	if (self.enemy != world)
	{
		if (self.health < self.max_health - 20)
			self.icky_onAttack = TRUE;

		vector toEnemy = (self.enemy.origin + self.enemy.view_ofs)
			- (self.origin + self.view_ofs);
		float dist = vlen(toEnemy);

		// 2D facing dot toward the enemy
		vector flat = toEnemy;
		flat_z = 0;
		flat = normalize(flat);
		makevectors([0, self.angles_y, 0]);
		float flDot = flat * v_forward;

		// CheckMeleeAttack1: touched within 0.2s and facing them.
		if (flDot >= 0.7 && self.icky_enemyTouched > time - 0.2
			&& time >= self.m_flNextAttack)
		{
			float dur = Monster_PlayAnimByName(self, "attack");
			if (dur <= 0) dur = 0.6;
			self.icky_animLock  = time + dur;
			self.m_flNextAttack = time + dur;
			self.icky_biteTime  = time + 0.15;	// AE_SHAKE event point
			self.icky_saveVel   = normalize(toEnemy) * self.icky_flightSpeed;
		}
		else if (flDot > -0.7
			&& (self.icky_onAttack || (dist <= 192 && self.icky_idealDist <= 192)))
		{
			if (self.icky_mode != ICKY_MODE_CHASE)
				Icky_AttackSound();	// GetScheduleOfType(SCHED_CHASE_ENEMY)
			self.icky_mode = ICKY_MODE_CHASE;
			self.icky_saveVel = normalize(toEnemy) * self.icky_flightSpeed;
		}
		else
		{
			self.icky_mode = ICKY_MODE_CIRCLE;
			Icky_CircleEnemy();
		}
	}
	else
	{
		// Idle swim-around: Stop() drops speed back to cruise.
		self.icky_mode = ICKY_MODE_IDLE;
		if (!self.icky_onAttack)
			self.icky_flightSpeed = 80;

		if (time > self.icky_nextAlert)
		{
			if (random() < 0.5) Icky_IdleSound();
			self.icky_nextAlert = time + random(4, 8);
		}
	}

	Icky_Swim();

	if (self.icky_blink < time)
	{
		self.skin = ICKY_EYE_CLOSED;
		if (self.icky_blink + 0.2 < time)
		{
			self.icky_blink = time + random(3, 4);
			self.skin = self.icky_onAttack ? ICKY_EYE_MAD : ICKY_EYE_BASE;
		}
	}
}

void monster_ichthyosaur()
{
	if (Monster_RemoveIfSpent()) return;
	if (RemoveInDeathmatch()) return;

	Icky_Precache();

	setmodel(self, ICKY_MODEL);
	setsize(self, '-32 -32 -32', '32 32 32');

	self.solid      = SOLID_SLIDEBOX;
	self.movetype   = MOVETYPE_FLY;
	self.flags      = self.flags | FL_MONSTER | FL_SWIM;
	if (self.spawnflags & SF_MONSTER_HITMONSTERCLIP)
		self.flags = self.flags | FL_MONSTERCLIP;
	self.health     = ICKY_HEALTH;
	self.max_health = self.health;
	self.view_ofs   = '0 0 16';
	self.yaw_speed  = YAW_HL(100);
	self.monster_bloodColor    = BLOOD_COLOR_GREEN;
	self.monster_fieldOfView = -0.7;	// VIEW_FIELD_WIDE
	self.monster_state  = MONSTERSTATE_NONE;
	self.skin       = ICKY_EYE_BASE;

	self.frameByName = Icky_FrameByName;
	self.th_pain     = Icky_Pain;
	self.th_die      = Icky_Die;
	self.touch       = Icky_BiteTouch;
	self.usehl       = Icky_CombatUse;

	Monster_InitTakeDamage();

	self.icky_idealDist   = 384;
	self.icky_minSpeed    = 80;
	self.icky_maxSpeed    = 300;
	self.icky_maxDist     = 384;
	self.icky_flightSpeed = ICKY_SPEED;
	self.icky_blink       = time + random(3, 4);
	self.icky_nextAlert   = time + random(4, 8);

	if (self.spawnflags & SF_MONSTER_WAIT_TILL_SEEN)
	{
		self.monster_isAsleep = TRUE;
		self.monster_state = MONSTERSTATE_IDLE;
	}

	makevectors([0, self.angles_y, 0]);
	self.icky_saveVel = v_forward * self.icky_flightSpeed;
	self.velocity     = self.icky_saveVel;

	Monster_PlayAnimByName(self, "swim");
	self.think      = Icky_SwimThink;
	self.nextthink  = time + ICKY_THINK_RATE + random() * 0.5;
	total_monsters  = total_monsters + 1;
}
