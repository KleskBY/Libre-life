// no entity-local spawnflags.
// Anims (data/models/leech.iqm.framegroups): swim=0, swim2=1, attack=2,
//   hover=3, leftturn=4, rightturn=5, death=6, death_end=7
// Activity map: ACT_SWIM=swim, ACT_TURN_LEFT/RIGHT=leftturn/rightturn,
//   ACT_MELEE_ATTACK1=attack, ACT_TWITCH(flop)=hover, ACT_DIESIMPLE=death,
//   ACT_DIEFORWARD=death_end.

#define LEECH_MODEL          "models/leech.iqm"

#define LEECH_HEALTH         Skill_GetValue("sk_leech_health", 2)
#define LEECH_DMG_BITE       Skill_GetValue("sk_leech_dmg_bite", 2)
#define LEECH_ACCELERATE     10
#define LEECH_CHECK_DIST     45
#define LEECH_SWIM_SPEED     50
#define LEECH_SWIM_ACCEL     80
#define LEECH_SWIM_DECEL     10
#define LEECH_TURN_RATE      90
#define LEECH_SIZEX          10
#define LEECH_FRAMETIME      0.1
#define LEECH_DIST_LOOK      750

#define LEECH_FR_SWIM        0
#define LEECH_FR_SWIM2       1
#define LEECH_FR_ATTACK      2
#define LEECH_FR_HOVER       3
#define LEECH_FR_LEFTTURN    4
#define LEECH_FR_RIGHTTURN   5
#define LEECH_FR_DEATH       6
#define LEECH_FR_DEATH_END   7

.float  leech_turning;
.float  leech_pathBlocked;     // m_fPathBlocked
.float  leech_accelerate;
.float  leech_obstacle;        // m_obstacle
.float  leech_top;             // m_top
.float  leech_bottom;          // m_bottom
.float  leech_height;          // m_height
.float  leech_waterTime;       // m_waterTime
.float  leech_sideTime;        // m_sideTime
.float  leech_zTime;           // m_zTime
.float  leech_stateTime;       // m_stateTime
.float  leech_attackSoundTime; // m_attackSoundTime
.float  leech_activity;        // m_Activity (ACT_*)
.float  leech_animEnd;         // time the current anim cycle finishes
.float  leech_biteTime;        // pending LEECH_AE_ATTACK event; 0 = none
.vector leech_oldOrigin;

float Leech_FrameByName(string fname)
{
	if (fname == "swim")       return LEECH_FR_SWIM;
	if (fname == "swim2")      return LEECH_FR_SWIM2;
	if (fname == "attack")     return LEECH_FR_ATTACK;
	if (fname == "hover")      return LEECH_FR_HOVER;
	if (fname == "leftturn")   return LEECH_FR_LEFTTURN;
	if (fname == "rightturn")  return LEECH_FR_RIGHTTURN;
	if (fname == "death")      return LEECH_FR_DEATH;
	if (fname == "death_end")  return LEECH_FR_DEATH_END;
	return -1;
}

void Leech_Precache()
{
	precache_model(LEECH_MODEL);
	precache_sound("leech/leech_bite1.wav");
	precache_sound("leech/leech_bite2.wav");
	precache_sound("leech/leech_bite3.wav");
	precache_sound("leech/leech_alert1.wav");
	precache_sound("leech/leech_alert2.wav");
}

void Leech_AttackSound()
{
	if (time <= self.leech_attackSoundTime) return;
	self.leech_attackSoundTime = time + 0.5;
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100,
		"leech/leech_bite1.wav", "leech/leech_bite2.wav", "leech/leech_bite3.wav");
}

void Leech_AlertSound()
{
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM * 0.5, PITCH_NORM,
		"leech/leech_alert1.wav", "leech/leech_alert2.wav");
}

float Leech_InWater(vector p)
{
	float pc = pointcontents(p);
	return (pc == CONTENT_WATER || pc == CONTENT_SLIME);
}

// eyes that may be above the surface of its own pool.
float Leech_Visible(entity targ)
{
	traceline(self.origin + self.view_ofs, targ.origin + targ.view_ofs, TRUE, self);
	return (trace_fraction == 1);
}

void Leech_MakeVectors()
{
	makevectors([-Math_SignedAngle(self.angles_x), self.angles_y, self.angles_z]);
}

string Leech_ActAnim(float act)
{
	if (act == ACT_TURN_LEFT)     return "leftturn";
	if (act == ACT_TURN_RIGHT)    return "rightturn";
	if (act == ACT_MELEE_ATTACK1) return "attack";
	if (act == ACT_TWITCH)        return "hover";	// flop
	if (act == ACT_DIESIMPLE)     return "death";
	if (act == ACT_DIEFORWARD)    return "death_end";
	return "swim";
}

void Leech_SetActivity(float act)
{
	if (self.leech_activity == act) return;
	self.leech_activity = act;

	float dur = Monster_PlayAnimByName(self, Leech_ActAnim(act));
	if (dur <= 0) dur = 0.5;
	self.leech_animEnd = time + dur;

	// LEECH_AE_ATTACK fires partway into each attack cycle.
	self.leech_biteTime = (act == ACT_MELEE_ATTACK1) ? time + 0.15 : 0;
}

float Leech_WaterSurface(vector position, float minz, float maxz)
{
	vector midUp = position;
	midUp_z = minz;
	if (!Leech_InWater(midUp)) return minz;

	midUp_z = maxz;
	if (Leech_InWater(midUp)) return maxz;

	float diff = maxz - minz;
	while (diff > 1)
	{
		midUp_z = minz + diff / 2;
		if (Leech_InWater(midUp)) minz = midUp_z;
		else                      maxz = midUp_z;
		diff = maxz - minz;
	}
	return midUp_z;
}

void Leech_RecalculateWaterlevel()
{
	vector vecTest = self.origin - '0 0 400';
	traceline(self.origin, vecTest, MOVE_MISSILE_2, self);
	if (trace_fraction != 1)
		self.leech_bottom = trace_endpos_z + 1;
	else
		self.leech_bottom = vecTest_z;

	self.leech_top = Leech_WaterSurface(self.origin, self.origin_z, self.origin_z + 400) - 1;

	float newBottom  = self.leech_bottom * 0.8 + self.leech_top * 0.2;
	self.leech_top    = self.leech_bottom * 0.2 + self.leech_top * 0.8;
	self.leech_bottom = newBottom;
	self.leech_height = random(self.leech_bottom, self.leech_top);
	self.leech_waterTime = time + random(5, 7);
}

entity Leech_BestVisibleEnemy()
{
	entity best = world;
	float bestDist = LEECH_DIST_LOOK;
	entity p = find(world, classname, "player");
	while (p)
	{
		if (IsAlive(p))
		{
			float d = vlen(p.origin - self.origin);
			if (d < bestDist && Leech_Visible(p))
			{
				best = p;
				bestDist = d;
			}
		}
		p = find(p, classname, "player");
	}
	return best;
}

void Leech_SwitchState()
{
	self.leech_stateTime = time + random(3, 6);
	if (self.monster_state == MONSTERSTATE_COMBAT)
	{
		self.enemy = world;
		self.monster_state = MONSTERSTATE_IDLE;
		self.leech_sideTime = 0;
	}
	else if (!(self.spawnflags & SF_MONSTER_PRISONER))
	{
		entity pEnemy = Leech_BestVisibleEnemy();
		if (pEnemy != world && pEnemy.waterlevel != 0)
		{
			self.enemy = pEnemy;
			self.monster_state = MONSTERSTATE_COMBAT;
			self.leech_stateTime = time + random(18, 25);
			Leech_AlertSound();
		}
	}
}

void Leech_AttackEvent()
{
	Leech_AttackSound();

	entity pEnemy = self.enemy;
	if (pEnemy != world && pEnemy)
	{
		Leech_MakeVectors();
		vector face = v_forward;
		face_z = 0;
		face = normalize(face);

		vector dir = pEnemy.origin - self.origin;
		dir_z = 0;
		dir = normalize(dir);

		if (dir * face > 0.9)
			T_Damage(pEnemy, self, self, LEECH_DMG_BITE, DMG_SLASH);
	}
	self.leech_stateTime = self.leech_stateTime - 2;
}

// Leaves v_forward/v_right set for the caller.
float Leech_ObstacleDistance(entity pTarget)
{
	Leech_MakeVectors();

	vector vecTest = self.origin + v_forward * LEECH_CHECK_DIST;
	traceline(self.origin, vecTest, MOVE_MISSILE_2, self);

	if (trace_startsolid)
		self.speed = -LEECH_SWIM_SPEED * 0.5;

	if (trace_fraction != 1)
	{
		if (pTarget == world || trace_ent != pTarget)
			return trace_fraction;
		// not already near our target height.
		if (fabs(self.leech_height - self.origin_z) > 10)
			return trace_fraction;
	}

	if (self.leech_sideTime < time)
	{
		vecTest = self.origin + v_right * (LEECH_SIZEX * 2) + v_forward * LEECH_CHECK_DIST;
		traceline(self.origin, vecTest, MOVE_MISSILE_2, self);
		if (trace_fraction != 1) return trace_fraction;

		vecTest = self.origin - v_right * (LEECH_SIZEX * 2) + v_forward * LEECH_CHECK_DIST;
		traceline(self.origin, vecTest, MOVE_MISSILE_2, self);
		if (trace_fraction != 1) return trace_fraction;

		self.leech_sideTime = time + random(0.5, 1);
	}
	return 1;
}

// activity selection, out-of-water flop.
void Leech_UpdateMotion(float canMelee)
{
	float flapspeed = (self.speed - self.leech_accelerate) / LEECH_ACCELERATE;
	self.leech_accelerate = self.leech_accelerate * 0.8 + self.speed * 0.2;

	if (flapspeed < 0) flapspeed = -flapspeed;
	flapspeed = flapspeed + 1;
	flapspeed = Math_Clamp(flapspeed, 0.5, 1.9);

	if (!self.leech_pathBlocked)
		self.avelocity_y = self.ideal_yaw;
	else
		self.avelocity_y = self.ideal_yaw * self.leech_obstacle;

	float ideal;
	if (self.avelocity_y > 150)       ideal = ACT_TURN_LEFT;
	else if (self.avelocity_y < -150) ideal = ACT_TURN_RIGHT;
	else                              ideal = ACT_SWIM;

	// Lean toward the target height.
	float delta = self.leech_height - self.origin_z;
	float targetPitch;
	if (delta < -10)     targetPitch = -30;
	else if (delta > 10) targetPitch = 30;
	else                 targetPitch = 0;

	self.angles_x = Math_Approach(targetPitch, Math_SignedAngle(self.angles_x), 60 * LEECH_FRAMETIME);

	// Bank into the turn.
	self.avelocity_z = -(Math_SignedAngle(self.angles_z) + (self.avelocity_y * 0.25));

	if (self.monster_state == MONSTERSTATE_COMBAT && canMelee)
		ideal = ACT_MELEE_ATTACK1;

	if (!Leech_InWater(self.origin))
	{
		self.movetype = MOVETYPE_TOSS;
		ideal = ACT_TWITCH;
		self.velocity = '0 0 0';

		self.angles_z = 0;
		self.angles_x = 0;

		if (flapspeed < 1) flapspeed = 1;
	}
	else if (self.movetype == MOVETYPE_TOSS)
	{
		self.movetype = MOVETYPE_FLY;
		self.flags = self.flags - (self.flags & FL_ONGROUND);
		Leech_RecalculateWaterlevel();
		self.leech_waterTime = time + 2;
	}

	Leech_SetActivity(ideal);

	// Restart the attack cycle while the melee condition holds
	// sequence and re-fires the anim event each pass).
	if (self.leech_activity == ACT_MELEE_ATTACK1 && time >= self.leech_animEnd)
	{
		float dur = Monster_PlayAnimByName(self, "attack");
		if (dur <= 0) dur = 0.5;
		self.leech_animEnd = time + dur;
		self.leech_biteTime = time + 0.15;
	}

	if (self.leech_biteTime && time >= self.leech_biteTime)
	{
		self.leech_biteTime = 0;
		Leech_AttackEvent();
	}

	self.framerate = flapspeed;
}

void Leech_SwimThink()
{
	float targetSpeed = LEECH_SWIM_SPEED;
	float targetYaw = 0;
	entity pTarget = world;
	float canMelee = FALSE;

	if (!checkclient())
	{
		self.nextthink = time + random(1, 1.5);
		self.velocity = '0 0 0';
		return;
	}
	self.nextthink = time + LEECH_FRAMETIME;

	if (self.leech_waterTime < time)
		Leech_RecalculateWaterlevel();
	if (self.leech_stateTime < time)
		Leech_SwitchState();

	if (self.monster_state == MONSTERSTATE_COMBAT)
	{
		pTarget = self.enemy;
		if (pTarget == world || !pTarget || !IsAlive(pTarget))
		{
			pTarget = world;
			Leech_SwitchState();
		}
		else
		{
			self.leech_height = pTarget.origin_z + pTarget.view_ofs_z - 5;
			self.leech_height = Math_Clamp(self.leech_height, self.leech_bottom, self.leech_top);

			vector location = pTarget.origin - self.origin;
			location_z = location_z + pTarget.view_ofs_z;
			if (vlen(location) < 40)
				canMelee = TRUE;

			targetYaw = vectoyaw(location);
			targetYaw = Math_AngleDistance(targetYaw, Math_AngleMod(self.angles_y));

			if (targetYaw < -(LEECH_TURN_RATE * 0.75))
				targetYaw = -(LEECH_TURN_RATE * 0.75);
			else if (targetYaw > (LEECH_TURN_RATE * 0.75))
				targetYaw = (LEECH_TURN_RATE * 0.75);
			else
				targetSpeed = targetSpeed * 2;
		}
	}
	else
	{
		// Idle wander: drift depth and make random turns.
		if (self.leech_zTime < time)
		{
			float newHeight = random(self.leech_bottom, self.leech_top);
			self.leech_height = 0.5 * self.leech_height + 0.5 * newHeight;
			self.leech_zTime = time + random(1, 4);
		}
		if (random() < 0.1)
			targetYaw = Math_RandomInt(-30, 30);

		if (vlen(self.origin - self.leech_oldOrigin) < 1)
			self.leech_sideTime = 0;
	}

	self.leech_obstacle = Leech_ObstacleDistance(pTarget);
	self.leech_oldOrigin = self.origin;
	if (self.leech_obstacle < 0.1)
		self.leech_obstacle = 0.1;

	if (self.leech_obstacle == 1)
	{
		self.leech_turning = 0;
		self.leech_pathBlocked = FALSE;
		self.speed = Math_Approach(targetSpeed, self.speed, LEECH_SWIM_ACCEL * LEECH_FRAMETIME);
		self.velocity = v_forward * self.speed;
	}
	else
	{
		self.leech_obstacle = 1 / self.leech_obstacle;
		self.leech_pathBlocked = TRUE;

		if (self.leech_turning == 0)
		{
			// Leech is blocked and not currently turning.
			vector vecTest = self.origin + (v_right * LEECH_SIZEX) + (v_forward * LEECH_CHECK_DIST);
			traceline(self.origin, vecTest, MOVE_MISSILE_2, self);
			float flRightSide = trace_fraction;

			vecTest = self.origin - (v_right * LEECH_SIZEX) + (v_forward * LEECH_CHECK_DIST);
			traceline(self.origin, vecTest, MOVE_MISSILE_2, self);
			float flLeftSide = trace_fraction;

			float clearDelta = flRightSide - flLeftSide;
			if (clearDelta > 0.1 || (clearDelta > -0.1 && random() < 0.5))
				self.leech_turning = -LEECH_TURN_RATE;
			else
				self.leech_turning = LEECH_TURN_RATE;
		}
		self.speed = Math_Approach(-(LEECH_SWIM_SPEED * 0.5), self.speed,
			LEECH_SWIM_DECEL * LEECH_FRAMETIME * self.leech_obstacle);
		self.velocity = v_forward * self.speed;
	}
	self.ideal_yaw = self.leech_turning + targetYaw;
	Leech_UpdateMotion(canMelee);
}

// Damage / touch

float Leech_TakeDamage(entity inflictor, entity attacker, float damage, float dmgType)
{
	self.velocity = '0 0 0';
	if (inflictor && inflictor != world)
		self.velocity = normalize(self.origin - inflictor.origin) * 25;

	return Monster_TakeDamage(inflictor, attacker, damage, dmgType);
}

// velocity directly (SwimThink re-owns it next tick).
void Leech_PushTouch()
{
	if (other.flags & FL_CLIENT)
		self.velocity = self.velocity + other.velocity;
}

// takedamage=NO and cleared .touch before th_die runs.
void Leech_DeadThink()
{
	if (time >= self.leech_animEnd)   // m_fSequenceFinished
	{
		if (self.leech_activity == ACT_DIEFORWARD)
		{
			self.think = SUB_Null;
			self.framerate = 0;       // Monster_StopAnimation
			self.nextthink = 0;
			return;
		}
		if (self.flags & FL_ONGROUND)
		{
			self.solid = SOLID_NOT;
			Leech_SetActivity(ACT_DIEFORWARD);
		}
	}
	self.nextthink = time + 0.1;

	if (self.velocity_x != 0 || self.velocity_y != 0)
	{
		traceline(self.origin, self.origin + self.velocity * 0.5, MOVE_MISSILE_2, self);
		if (trace_fraction != 1)
		{
			self.velocity_x = 0;
			self.velocity_y = 0;
		}
	}
}

void Leech_Die()
{
	if (Leech_InWater(self.origin))
	{
		// Spin and sink; DeadThink handles death_end upon hitting ground.
		self.angles_z = 0;
		self.angles_x = 0;
		setorigin(self, self.origin + '0 0 1');
		self.avelocity = '0 0 0';
		if (random() < 0.7)
			self.avelocity_y = Math_RandomInt(-720, 720);
		self.gravity = 0.02;
		self.flags = self.flags - (self.flags & FL_ONGROUND);
		Leech_SetActivity(ACT_DIESIMPLE);
	}
	else
		Leech_SetActivity(ACT_DIEFORWARD);

	self.movetype  = MOVETYPE_TOSS;
	self.deadflag  = DEAD_DEAD;
	self.think     = Leech_DeadThink;
	self.nextthink = time + 0.1;
}

void monster_leech()
{
	if (Monster_RemoveIfSpent()) return;
	if (RemoveInDeathmatch()) return;

	Leech_Precache();

	setmodel(self, LEECH_MODEL);
	// really point-sized.
	setsize(self, '-1 -1 0', '1 1 2');

	self.solid      = SOLID_SLIDEBOX;
	self.movetype   = MOVETYPE_FLY;
	self.flags      = self.flags | FL_SWIM | FL_MONSTER;
	self.health     = LEECH_HEALTH;
	self.max_health = self.health;
	self.monster_fieldOfView = -0.5;
	self.monster_distLook    = LEECH_DIST_LOOK;
	self.monster_bloodColor    = DONT_BLEED;
	self.view_ofs        = '0 0 0';

	self.frameByName = Leech_FrameByName;
	self.th_die      = Leech_Die;
	self.touch       = Leech_PushTouch;

	Monster_InitTakeDamage();
	self.takeDmgFn = Leech_TakeDamage;

	self.leech_turning     = 0;
	self.leech_pathBlocked = FALSE;
	Leech_SetActivity(ACT_SWIM);
	self.monster_state  = MONSTERSTATE_IDLE;
	self.leech_stateTime = time + random(1, 5);
	self.leech_waterTime = 0;            // Activate(): recalc bounds on first think

	self.think     = Leech_SwimThink;
	self.nextthink = time + 0.1;
	total_monsters = total_monsters + 1;
}
