// No entity-local spawnflags; only shared SF_MONSTER_GAG = 2.
// spawn: renderamt=20 + kRenderTransTexture (cloaked by default).
// Anim indices (data/models/hassassin.iqm.framegroups):
//   idle1=0, idle3=1, idle2=2, run=3, walk=4, shoot_blend1=5, grenadethrow=6,
//   kick=7, kickshort=8, death_during_run=9, die_backwards=10, die_simple=11,
//   jump=12, fly_up=13, fly_down=14, fly_attack=15, landfromjump=16

#define HASSN_MODEL              "models/hassassin.iqm"
#define HASSN_HEALTH             Skill_GetValue("sk_hassassin_health", 50)
#define HASSN_FOV                0.5
#define HASSN_SIGHT_RANGE        1500
#define HASSN_ATTACK_RANGE       1024
#define HASSN_MELEE_RANGE        80
#define HASSN_BURST_DAMAGE       Skill_GetValue("sk_9mm_bullet", 5)
#define HASSN_BURST_SHOTS        3
#define HASSN_BURST_DELAY        0.1
#define HASSN_ATTACK_COOLDOWN    1.2
#define HASSN_BULLET_SPREAD      0.03
#define HASSN_JUMP_BULLET_SPREAD 0.08
#define HASSN_GRENADE_RANGE      256
#define HASSN_GRENADE_MAX        1200
#define HASSN_GRENADE_COOLDOWN   12
#define HASSN_STRAFE_INTERVAL    1.2
#define HASSN_STRAFE_DIST        48
#define HASSN_MELEE_DAMAGE       18
#define HASSN_JUMP_COOLDOWN      5
#define HASSN_JUMP_FORWARD       320
#define HASSN_JUMP_UP            350
#define HASSN_CLOAK_FAR          20
#define HASSN_CLOAK_VISIBLE      255
#define HASSN_CLOAK_STEP         90

#define HASSN_FR_IDLE1           0
#define HASSN_FR_IDLE3           1
#define HASSN_FR_IDLE2           2
#define HASSN_FR_RUN             3
#define HASSN_FR_WALK            4
#define HASSN_FR_SHOOT           5
#define HASSN_FR_GRENADETHROW    6
#define HASSN_FR_KICK            7
#define HASSN_FR_KICKSHORT       8
#define HASSN_FR_DEATH_RUN       9
#define HASSN_FR_DIEBACK         10
#define HASSN_FR_DIESIMPLE       11
#define HASSN_FR_JUMP            12
#define HASSN_FR_FLY_UP          13
#define HASSN_FR_FLY_DOWN        14
#define HASSN_FR_FLY_ATTACK      15
#define HASSN_FR_LANDFROMJUMP    16

#define HASSN_FIRE1_SOUND        "weapons/pl_gun1.wav"
#define HASSN_FIRE2_SOUND        "weapons/pl_gun2.wav"
#define HASSN_DECLOAK_SOUND      "debris/beamstart1.wav"
#define HASSN_LAND_SOUND         "player/pl_jumpland2.wav"
#define HASSN_KICKHIT_SOUND      "zombie/claw_strike1.wav"

// Air state
#define HASSN_AS_GROUND   0
#define HASSN_AS_JUMPING  1
#define HASSN_AS_LANDING  2

// Combat substate
#define HACS_RUN       0
#define HACS_ATTACK    1
#define HACS_KICK      2
#define HACS_GRENADE   3
#define HACS_LANDANIM  4
#define HACS_FLEE      5   // running from a live grenade (highest priority, ground only)

#define HASSN_GRENADE_FEAR_RAD  300   // flee live grenades within this radius

.float hassn_nextAttack;
.float hassn_burstShots;
.float hassn_nextStrafe;
.float hassn_nextJump;
.float hassn_nextGrenade;
.float hassn_combatState;
.float hassn_subStateEnd;
.float hassn_actTime;          // one-shot mid-anim action time (kick/throw); 0 = already fired
.float hassn_airState;
.float hassn_lastDmgDir;
.vector hassn_fleeFrom;         // danger point to run away from (grenade origin)
.entity hassn_fleeMarker;      // temp movetogoal target used while fleeing
.float hassn_ducking;
.float hassn_moving;
.vector hassn_lkp;

float HAssn_FrameByName(string name)
{
	if (name == "idle1")             return HASSN_FR_IDLE1;
	if (name == "idle2")             return HASSN_FR_IDLE2;
	if (name == "idle3")             return HASSN_FR_IDLE3;
	if (name == "run")               return HASSN_FR_RUN;
	if (name == "walk")              return HASSN_FR_WALK;
	if (name == "shoot_blend1")      return HASSN_FR_SHOOT;
	if (name == "grenadethrow")      return HASSN_FR_GRENADETHROW;
	if (name == "kick")              return HASSN_FR_KICK;
	if (name == "kickshort")         return HASSN_FR_KICKSHORT;
	if (name == "death_during_run")  return HASSN_FR_DEATH_RUN;
	if (name == "die_backwards")     return HASSN_FR_DIEBACK;
	if (name == "die_simple")        return HASSN_FR_DIESIMPLE;
	if (name == "jump")              return HASSN_FR_JUMP;
	if (name == "fly_up")            return HASSN_FR_FLY_UP;
	if (name == "fly_down")          return HASSN_FR_FLY_DOWN;
	if (name == "fly_attack")        return HASSN_FR_FLY_ATTACK;
	if (name == "landfromjump")      return HASSN_FR_LANDFROMJUMP;
	return -1;
}

void HAssn_Precache()
{
	precache_model(HASSN_MODEL);
	precache_model("models/w_grenade.iqm");
	precache_sound(HASSN_FIRE1_SOUND);
	precache_sound(HASSN_FIRE2_SOUND);
	precache_sound(HASSN_DECLOAK_SOUND);
	precache_sound(HASSN_LAND_SOUND);
	precache_sound(HASSN_KICKHIT_SOUND);
	precache_sound("weapons/explode3.wav");
}

void HAssn_PlayFrame(float fr)
{
	if (self.frame == fr) return;
	self.frame      = fr;
	self.frame1time = time;
	self.framerate  = 1;
}

void HAssn_SetStance(float ducking)
{
	if (ducking && !self.hassn_ducking)
	{
		self.hassn_ducking = TRUE;
		setsize(self, VEC_HUMAN_HULL_MIN, VEC_HUMAN_HULL_DUCK);
	}
	else if (!ducking && self.hassn_ducking)
	{
		vector oldmin = self.mins, oldmax = self.maxs;
		setsize(self, VEC_HUMAN_HULL_MIN, VEC_HUMAN_HULL_MAX);
		tracebox(self.origin, VEC_HUMAN_HULL_MIN, VEC_HUMAN_HULL_MAX,
		         self.origin, FALSE, self);
		if (trace_startsolid || trace_allsolid)
		{
			setsize(self, oldmin, oldmax);   // no headroom, stay ducked
			return;
		}
		self.hassn_ducking = FALSE;
	}
}

float HAssn_CanSee(entity tgt)
{
	if (!tgt) return FALSE;
	traceline(self.origin + self.view_ofs, tgt.origin + tgt.view_ofs, FALSE, self);
	return (trace_fraction == 1.0 || trace_ent == tgt);
}

entity HAssn_FindEnemy()
{
	entity head = findradius(self.origin, HASSN_SIGHT_RANGE);
	entity best = world;
	float bestDist = HASSN_SIGHT_RANGE + 1;
	while (head)
	{
		if (head != self && head.health > 0 && !(head.flags & FL_NOTARGET))
		{
			if ((head.flags & FL_CLIENT) && HAssn_CanSee(head))
			{
				float d = vlen(head.origin - self.origin);
				if (d < bestDist) { best = head; bestDist = d; }
			}
		}
		head = head.chain;
	}
	return best;
}

void HAssn_ApplyAlpha()
{
	self.rendermode = 4;                       // kRenderTransAlpha
	self.alpha = self.renderamt / 255;
	if (self.alpha < 0.01) self.alpha = 0.01;  // DP treats alpha 0 as "default=opaque"
}

void HAssn_UpdateCloak()
{
	// Cloaks on every skill level now (previously restricted to SKILL_HARD)
	// stationary/grounded/has-a-live-enemy is still required so it reads as
	// a deliberate stealth stance, not a random flicker.
	float tgt = HASSN_CLOAK_VISIBLE;
	if (self.enemy && self.enemy.health > 0
		&& self.deadflag == DEAD_NO
		&& !self.hassn_moving                  // not ACT_RUN / ACT_WALK
		&& (self.flags & FL_ONGROUND))         // airborne = always visible
		tgt = HASSN_CLOAK_FAR;

	// Plays a soft shimmer when the fade-out starts from fully visible
	if (self.renderamt > tgt && self.renderamt == HASSN_CLOAK_VISIBLE)
		Sound_Play(self, CHAN_BODY, 0.2, ATTN_NORM, PITCH_NORM, HASSN_DECLOAK_SOUND);
	if (self.renderamt < tgt) self.renderamt = self.renderamt + HASSN_CLOAK_STEP;
	if (self.renderamt > tgt) self.renderamt = self.renderamt - HASSN_CLOAK_STEP;
	if (self.renderamt < HASSN_CLOAK_FAR) self.renderamt = HASSN_CLOAK_FAR;
	if (self.renderamt > HASSN_CLOAK_VISIBLE) self.renderamt = HASSN_CLOAK_VISIBLE;

	HAssn_ApplyAlpha();
}

// Fire MP5
vector HAssn_ShootOrigin()
{
	// Gun sits lower while crouched to fire.
	if (self.hassn_ducking) return self.origin + '0 0 28';
	return self.origin + '0 0 50';
}

void HAssn_PlayFireSnd()
{
	float vol = 0.6 + random() * 0.2;
	Sound_Play(self, CHAN_WEAPON, vol, ATTN_NORM, 100, HASSN_FIRE1_SOUND, HASSN_FIRE2_SOUND);
}

void HAssn_FireMP5(float spread)
{
	if (!self.enemy) return;

	vector shootOrigin = HAssn_ShootOrigin();
	vector aim = self.enemy.origin + self.enemy.view_ofs - shootOrigin;
	aim = normalize(aim);

	makevectors(vectoangles(aim));
	aim = aim
		+ v_right * ((random() * 2 - 1) * spread)
		+ v_up    * ((random() * 2 - 1) * spread);
	aim = normalize(aim);

	traceline(shootOrigin, shootOrigin + aim * 4096, FALSE, self);
	if (trace_fraction < 1.0 && trace_ent && trace_ent.takedamage != DAMAGE_NO)
		T_Damage(trace_ent, self, self, HASSN_BURST_DAMAGE, DMG_BULLET);

	HAssn_PlayFireSnd();
	self.effects = self.effects | EF_MUZZLEFLASH;
}

void HAssn_ThrowGrenade()
{
	if (!self.enemy) return;
	makevectors(self.angles);
	vector src = self.origin + v_forward * 18 + '0 0 36';

	vector to = self.enemy.origin - src;
	float horiz = vlen([to_x, to_y, 0]);
	if (horiz < 1) horiz = 1;
	vector dir = normalize([to_x, to_y, 0]);
	float speed = horiz / 1.4;
	if (speed < 450)  speed = 450;
	if (speed > 1100) speed = 1100;

	vector vel = dir * speed + '0 0 1' * (speed * 0.55);
	HandGrenade_Create(self, src, vel, 3.0);
}

// Sidestep / strafe
float HAssn_TryStrafe()
{
	makevectors(self.angles);
	float canRight = FALSE, canLeft = FALSE;
	traceline(self.origin, self.origin + v_right * (HASSN_STRAFE_DIST + 16), FALSE, self);
	if (trace_fraction == 1.0) canRight = TRUE;
	traceline(self.origin, self.origin - v_right * (HASSN_STRAFE_DIST + 16), FALSE, self);
	if (trace_fraction == 1.0) canLeft = TRUE;

	float dir = 0;
	if (canLeft && canRight) dir = (random() >= 0.5) ? 1 : -1;
	else if (canLeft)  dir = -1;
	else if (canRight) dir =  1;
	if (!dir) return FALSE;

	if (!walkmove(self.angles_y + (dir > 0 ? 270 : 90), HASSN_STRAFE_DIST))
		return FALSE;
	self.hassn_nextStrafe = time + HASSN_STRAFE_INTERVAL + random();
	return TRUE;
}

entity HAssn_SenseGrenade()
{
	entity g = findradius(self.origin, HASSN_GRENADE_FEAR_RAD);
	while (g)
	{
		if (g.classname == "grenade" && g.owner != self && g.nextthink > time)
		{
			traceline(self.origin + self.view_ofs, g.origin, TRUE, self);
			if (trace_fraction >= 1.0 || trace_ent == g)
				return g;
		}
		g = g.chain;
	}
	return world;
}

void HAssn_FleeAway(vector danger)
{
	vector away = self.origin - danger;
	away_z = 0;
	if (vlen(away) < 1)
	{
		makevectors(self.angles);
		away = v_forward;
	}
	away = normalize(away);

	if (!self.hassn_fleeMarker)
	{
		entity mk = spawn();
		mk.classname = "hassn_fleemarker";
		mk.solid     = SOLID_NOT;
		mk.movetype  = MOVETYPE_NONE;
		mk.owner     = self;
		self.hassn_fleeMarker = mk;
	}
	setorigin(self.hassn_fleeMarker, self.origin + away * 256);
	self.goalentity = self.hassn_fleeMarker;
	self.ideal_yaw  = vectoyaw(away);
	ChangeYaw();
	movetogoal(24);
}

void HAssn_EnterFlee(entity gren)
{
	self.hassn_combatState = HACS_FLEE;
	self.hassn_subStateEnd = time + 1.2;
	self.hassn_fleeFrom    = gren.origin;
	self.monster_movementGoal    = MOVEGOAL_NONE;   // straight run-away, not node routing
	HAssn_SetStance(FALSE);
}

// Kick melee
void HAssn_KickHit()
{
	if (!self.enemy || self.enemy.health <= 0) return;

	// Forward-hull sweep (height-tolerant) instead of a horizontal facing dot, fixing issues with targets standing higher (staircase). Deals damage itself.
	makevectors(self.angles);
	entity pHurt = Combat_CheckTraceHullAttack(HASSN_MELEE_RANGE, HASSN_MELEE_DAMAGE, DMG_CLUB);
	if (!pHurt) return;

	Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, HASSN_KICKHIT_SOUND);

	if (pHurt.flags & FL_CLIENT)
	{
		pHurt.velocity = pHurt.velocity + v_forward * 300 + '0 0 220';
		pHurt.flags = pHurt.flags - (pHurt.flags & FL_ONGROUND);
		pHurt.punchangle = '12 0 0';
	}
}

void HAssn_LaunchJump()
{
	if (!self.enemy) return;
	if (!(self.flags & FL_ONGROUND)) return;

	makevectors(self.angles);

	// Aim toward enemy, but bias to one side for a flanking arc.
	vector to = self.enemy.origin - self.origin;
	to_z = 0;
	if (vlen(to) > 1) self.angles_y = vectoyaw(normalize(to));
	makevectors(self.angles);

	float sidewaysBias = (random() < 0.5) ? -1 : 1;
	vector vel = v_forward * HASSN_JUMP_FORWARD
	           + v_right   * (sidewaysBias * HASSN_JUMP_FORWARD * 0.35)
	           + '0 0 1'   * HASSN_JUMP_UP;

	HAssn_SetStance(FALSE);
	self.movetype = MOVETYPE_TOSS;
	self.flags = self.flags - (self.flags & FL_ONGROUND);
	self.velocity = vel;
	self.hassn_airState = HASSN_AS_JUMPING;
	self.hassn_nextJump = time + HASSN_JUMP_COOLDOWN;
	HAssn_PlayFrame(HASSN_FR_JUMP);
}

float HAssn_TouchingGround()
{
	if (self.flags & FL_ONGROUND) return TRUE;
	traceline(self.origin, self.origin + '0 0 -8', FALSE, self);
	return (trace_fraction < 1.0);
}

void HAssn_EnterLanding()
{
	self.hassn_airState = HASSN_AS_LANDING;
	self.movetype = MOVETYPE_STEP;
	self.velocity = '0 0 0';
	HAssn_PlayFrame(HASSN_FR_LANDFROMJUMP);
	Sound_Play(self, CHAN_BODY, 0.8, ATTN_NORM, PITCH_NORM, HASSN_LAND_SOUND);
	self.hassn_combatState = HACS_LANDANIM;
	self.hassn_subStateEnd = time + 0.4;
}

// Combat tick
void HAssn_Combat();
void HAssn_Stand();

void HAssn_EnterAttack()
{
	self.hassn_combatState = HACS_ATTACK;
	HAssn_PlayFrame(HASSN_FR_SHOOT);
}

void HAssn_EnterKick()
{
	self.hassn_combatState = HACS_KICK;
	self.hassn_subStateEnd = time + 0.6;
	self.hassn_actTime     = time + 0.3;   // one-shot hit latch (see hassn_actTime)
	HAssn_PlayFrame(HASSN_FR_KICK);
	self.frame1time = time;                // restart swing on back-to-back kicks
}

void HAssn_EnterGrenade()
{
	self.hassn_combatState = HACS_GRENADE;
	self.hassn_subStateEnd = time + 0.9;
	self.hassn_actTime     = time + 0.5;   // one-shot throw latch
	HAssn_PlayFrame(HASSN_FR_GRENADETHROW);
}

void HAssn_FaceEnemy()
{
	if (!self.enemy) return;
	vector to = self.enemy.origin - self.origin;
	to_z = 0;
	if (vlen(to) > 1)
	{
		self.ideal_yaw = vectoyaw(normalize(to));
		ChangeYaw();
	}
}

void HAssn_AirTick(float canSee)
{
	// Pick fly anim by vertical velocity.
	if (self.velocity_z > 30)       HAssn_PlayFrame(canSee ? HASSN_FR_FLY_ATTACK : HASSN_FR_FLY_UP);
	else if (self.velocity_z < -30) HAssn_PlayFrame(HASSN_FR_FLY_DOWN);
	else                            HAssn_PlayFrame(canSee ? HASSN_FR_FLY_ATTACK : HASSN_FR_JUMP);

	HAssn_FaceEnemy();
	if (canSee && time >= self.hassn_nextAttack)
	{
		HAssn_FireMP5(HASSN_JUMP_BULLET_SPREAD);
		self.hassn_burstShots = self.hassn_burstShots + 1;
		if (self.hassn_burstShots >= HASSN_BURST_SHOTS)
		{
			self.hassn_burstShots = 0;
			self.hassn_nextAttack = time + HASSN_ATTACK_COOLDOWN * 0.5;
		}
		else
		{
			self.hassn_nextAttack = time + HASSN_BURST_DELAY;
		}
	}

	// Land detection: ground contact while descending.
	if (self.velocity_z <= 5 && HAssn_TouchingGround())
	{
		HAssn_EnterLanding();
	}
}

void HAssn_Combat()
{
	// Schedule FIRST: if the body kills us (own blast, trigger_hurt during
	// movetogoal), th_die installs the death chain afterwards and wins.
	self.think     = HAssn_Combat;
	self.nextthink = time + 0.1;

	if (self.monster_cine && self.monster_cine != world)
	{
		self.think = HAssn_Combat;
		self.nextthink = time + 0.2;
		return;
	}

	if (self.enemy == self) self.enemy = world;   // never fight self (self-blast recovery)

	if (!self.enemy || self.enemy.health <= 0)
	{
		self.enemy = HAssn_FindEnemy();
		if (!self.enemy)
		{
			HAssn_SetStance(FALSE);
			self.hassn_combatState = HACS_RUN;
			self.think = HAssn_Stand;
			self.nextthink = time + 0.1;
			return;
		}
	}

	self.monster_state = MONSTERSTATE_COMBAT;

	float canSee = HAssn_CanSee(self.enemy);
	float dist   = vlen(self.enemy.origin - self.origin);
	if (canSee) self.hassn_lkp = self.enemy.origin;

	HAssn_UpdateCloak();
	self.hassn_moving = FALSE;

	if (self.hassn_airState == HASSN_AS_JUMPING)
	{
		HAssn_AirTick(canSee);
		return;
	}

	// Ground locomotion
	HAssn_FaceEnemy();

	float s = self.hassn_combatState;

	if (s != HACS_FLEE)
	{
		entity gren = HAssn_SenseGrenade();
		if (gren != world)
		{
			HAssn_EnterFlee(gren);
			self.hassn_moving = TRUE;
			return;
		}
	}

	if (s == HACS_FLEE)
	{
		HAssn_PlayFrame(HASSN_FR_RUN);
		self.hassn_moving = TRUE;
		// Track the grenade's live position (it's still moving) so we flee from
		// where it actually is, not its stale launch point.
		gren = HAssn_SenseGrenade();
		if (gren != world) self.hassn_fleeFrom = gren.origin;
		HAssn_FleeAway(self.hassn_fleeFrom);
		if (time >= self.hassn_subStateEnd && gren == world)
			self.hassn_combatState = HACS_RUN;
		return;
	}

	if (s == HACS_LANDANIM)
	{
		HAssn_PlayFrame(HASSN_FR_LANDFROMJUMP);
		if (time >= self.hassn_subStateEnd)
		{
			self.hassn_airState = HASSN_AS_GROUND;
			self.hassn_combatState = HACS_RUN;
		}
		return;
	}

	if (s == HACS_KICK)
	{
		HAssn_PlayFrame(HASSN_FR_KICK);
		if (self.hassn_actTime && time >= self.hassn_actTime)
		{
			HAssn_KickHit();
			self.hassn_actTime = 0;
		}
		if (time >= self.hassn_subStateEnd)
			self.hassn_combatState = HACS_RUN;
		return;
	}

	if (s == HACS_GRENADE)
	{
		HAssn_SetStance(TRUE);               // grenadethrow crouches
		HAssn_PlayFrame(HASSN_FR_GRENADETHROW);
		if (self.hassn_actTime && time >= self.hassn_actTime)
		{
			HAssn_ThrowGrenade();
			self.hassn_actTime = 0;
		}
		if (time >= self.hassn_subStateEnd)
			self.hassn_combatState = HACS_RUN;
		return;
	}

	if (s == HACS_ATTACK)
	{
		HAssn_SetStance(TRUE);               // shoot crouches
		HAssn_PlayFrame(HASSN_FR_SHOOT);

		if (!canSee)
		{
			HAssn_SetStance(FALSE);
			self.hassn_combatState = HACS_RUN;
			return;
		}

		if (time >= self.hassn_nextAttack)
		{
			HAssn_FireMP5(HASSN_BULLET_SPREAD);
			self.hassn_burstShots = self.hassn_burstShots + 1;
			if (self.hassn_burstShots >= HASSN_BURST_SHOTS)
			{
				self.hassn_burstShots = 0;
				self.hassn_nextAttack = time + HASSN_ATTACK_COOLDOWN;
				self.hassn_combatState = HACS_RUN;
				// Strafe between bursts.
				if (time >= self.hassn_nextStrafe) HAssn_TryStrafe();
			}
			else
			{
				self.hassn_nextAttack = time + HASSN_BURST_DELAY;
			}
		}
		return;
	}

	HAssn_SetStance(FALSE);                  // stand up for movement / melee
	// Melee point-blank.
	if (dist <= HASSN_MELEE_RANGE && canSee)
	{
		HAssn_EnterKick();
		return;
	}

	// Grenade when sight lost and at range.
	if (!canSee && time >= self.hassn_nextGrenade
		&& dist >= HASSN_GRENADE_RANGE && dist <= HASSN_GRENADE_MAX
		&& random() < 0.4)
	{
		HAssn_EnterGrenade();
		self.hassn_nextGrenade = time + HASSN_GRENADE_COOLDOWN;
		return;
	}

	// Periodic ballistic jump
	if (canSee && time >= self.hassn_nextJump && (self.flags & FL_ONGROUND)
		&& random() < 0.5)
	{
		HAssn_LaunchJump();
		return;
	}

	// Otherwise attack at range or chase.
	if (canSee && dist <= HASSN_ATTACK_RANGE && time >= self.hassn_nextAttack)
	{
		HAssn_EnterAttack();
	}
	else
	{
		HAssn_PlayFrame(HASSN_FR_RUN);
		vector goal = canSee ? self.enemy.origin : self.hassn_lkp;
		vector to = goal - self.origin;
		to_z = 0;
		if (vlen(to) > 1)
		{
			self.ideal_yaw = vectoyaw(normalize(to));
			ChangeYaw();
			self.goalentity = self.enemy;
			movetogoal(24);
			self.hassn_moving = TRUE;

		}
	}

}

void HAssn_Stand()
{
	if (Monster_YieldIfDead()) return;
	if (self.monster_cine && self.monster_cine != world)
	{
		self.think = HAssn_Stand;
		self.nextthink = time + 0.2;
		return;
	}

	HAssn_SetStance(FALSE);
	HAssn_PlayFrame(HASSN_FR_IDLE1);
	self.monster_state = MONSTERSTATE_IDLE;
	self.hassn_moving = FALSE;
	HAssn_UpdateCloak();

	entity threat = HAssn_FindEnemy();
	if (threat)
	{
		self.enemy = threat;
		self.hassn_lkp = threat.origin;
		self.hassn_combatState = HACS_RUN;
		self.think = HAssn_Combat;
		self.nextthink = time + 0.1;
		return;
	}

	self.think = HAssn_Stand;
	self.nextthink = time + 0.3;
}

void HAssn_Walk()
{
	if (Monster_YieldIfDead()) return;
	// Schedule FIRST so death thinks win
	self.think     = HAssn_Walk;
	self.nextthink = time + 0.1;

	if (self.monster_cine && self.monster_cine != world)
	{
		self.think = HAssn_Walk;
		self.nextthink = time + 0.2;
		return;
	}
	HAssn_PlayFrame(HASSN_FR_WALK);
	self.hassn_moving = TRUE;
	HAssn_UpdateCloak();
	AI_Walk(8);
}

void HAssn_Pain(entity attacker, float damage)
{
	if (self.monster_cine && self.monster_cine != world) return;   // scripted sequence owns us

	// Record damage direction for death-anim picker.
	if (attacker && attacker != world)
	{
		makevectors(self.angles);
		vector to = normalize(attacker.origin - self.origin);
		self.hassn_lastDmgDir = (to * v_forward > 0) ? 1 : -1;
	}

	if (self.pain_finished > time) return;
	self.pain_finished = time + 0.4;

	if (attacker != self && attacker.health > 0 && (attacker.flags & (FL_CLIENT | FL_MONSTER)))
	{
		self.enemy = attacker;
		self.hassn_lkp = attacker.origin;
		if (self.think != HAssn_Combat)
		{
			self.hassn_combatState = HACS_RUN;
			self.think = HAssn_Combat;
			self.nextthink = time + 0.1;
		}
		if (damage >= 15 && time >= self.hassn_nextStrafe && self.hassn_airState == HASSN_AS_GROUND)
			HAssn_TryStrafe();
	}
}

void HAssn_Die()
{
	Monster_ExitScriptedSequence();
	if (self.hassn_fleeMarker) { remove(self.hassn_fleeMarker); self.hassn_fleeMarker = world; }
	if (Gib_ShouldGib()) { Gib(); return; }

	self.takedamage  = DAMAGE_NO;
	self.solid       = SOLID_CORPSE;
	self.movetype    = MOVETYPE_TOSS;
	self.deadflag    = DEAD_DEAD;
	self.use         = SUB_Null;
	self.usehl       = __NULL__;
	self.object_caps = 0;
	self.flags       = self.flags - (self.flags & FL_MONSTER);

	HAssn_SetStance(FALSE);
	self.renderamt = HASSN_CLOAK_VISIBLE;
	HAssn_ApplyAlpha();

	float dieFrame;
	if (self.hassn_airState != HASSN_AS_GROUND)
		dieFrame = HASSN_FR_DEATH_RUN;
	else if (self.hassn_lastDmgDir == -1)
		dieFrame = HASSN_FR_DIEBACK;
	else
		dieFrame = HASSN_FR_DIESIMPLE;
	HAssn_PlayFrame(dieFrame);

	self.think     = SUB_Null;
	self.nextthink = -1;
}

void monster_human_assassin()
{
	if (Monster_RemoveIfSpent()) return;
	if (RemoveInDeathmatch()) return;

	HAssn_Precache();

	setmodel(self, HASSN_MODEL);
	setsize(self, VEC_HUMAN_HULL_MIN, VEC_HUMAN_HULL_MAX);

	self.solid       = SOLID_SLIDEBOX;
	self.movetype    = MOVETYPE_STEP;
	self.health      = HASSN_HEALTH;
	self.max_health  = self.health;
	self.yaw_speed   = YAW_HL(360);	// Sets yaw speed for fast turning
	self.view_ofs    = '0 0 50';

	self.monster_state      = MONSTERSTATE_IDLE;
	self.monster_idealState = MONSTERSTATE_IDLE;
	self.monster_bloodColor        = BLOOD_COLOR_RED;
	self.monster_fieldOfView     = HASSN_FOV;
	self.flags               = self.flags | FL_MONSTER;

	// Start cloaked (translate to engine .alpha immediately, not just renderamt).
	self.renderamt = HASSN_CLOAK_FAR;
	HAssn_ApplyAlpha();

	self.frameByName = HAssn_FrameByName;

	self.th_stand = HAssn_Stand;
	self.th_walk  = HAssn_Walk;
	self.th_run   = HAssn_Combat;
	self.th_pain  = HAssn_Pain;
	self.th_die   = HAssn_Die;

	Monster_InitTakeDamage();

	self.hassn_airState     = HASSN_AS_GROUND;
	self.hassn_combatState  = HACS_RUN;
	self.hassn_nextStrafe   = time + 1;
	self.hassn_nextJump     = time + 2;

	self.think     = HAssn_Stand;
	self.nextthink = time + 0.1 + random() * 0.5;
	total_monsters = total_monsters + 1;

	HAssn_PlayFrame(HASSN_FR_IDLE1);
}
