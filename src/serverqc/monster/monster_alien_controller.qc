
#define CON_MODEL           "models/controller.iqm"
#define CON_BALL_SPRITE     "sprites/xspark4.spr"

#define CON_FR_ATTACK1      0
#define CON_FR_ATTACK2      1
#define CON_FR_THROW        2
#define CON_FR_IDLE2        3
#define CON_FR_BLOCK        4
#define CON_FR_SHOOT        5
#define CON_FR_FLINCH1      6
#define CON_FR_FLINCH2      7
#define CON_FR_FALL         8
#define CON_FR_FORWARD      9
#define CON_FR_BACKWARD     10
#define CON_FR_UP           11
#define CON_FR_DOWN         12
#define CON_FR_RIGHT        13
#define CON_FR_LEFT         14
#define CON_FR_FLOAT        15
#define CON_FR_WALK         16
#define CON_FR_RUN          17
#define CON_FR_DIE          18

#define CON_HEALTH          Skill_GetValue("sk_controller_health", 60)
#define CON_DMG_ZAP         Skill_GetValue("sk_controller_dmgzap", 25)
#define CON_BALL_SPEED      Skill_GetValue("sk_controller_speedball", 800)
#define CON_DMG_BALL        Skill_GetValue("sk_controller_dmgball", 4)

#define CON_THINK_RATE      0.1
#define CON_FLINCH_DELAY    2
#define CON_GLOW_COLOR      '1.0 0.75 0.25' 

.vector con_estVel;        // smoothed enemy velocity for lead aim
.float  con_volleyShots;
.vector con_idealVel;      // head ball steering accumulator
.float  con_ballDie;       // head/energy ball expiry time

void Con_Run();
void Con_Stand();

void Con_IdleSound()
{
	if (self.waitmin >= time) return;
	self.waitmin = time + 3;
	if (random() > 0.25) return;
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100,
		"controller/con_idle1.wav", "controller/con_idle2.wav",
		"controller/con_idle3.wav", "controller/con_idle4.wav",
		"controller/con_idle5.wav");
}

void Con_AlertSound()
{
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100,
		"controller/con_alert1.wav", "controller/con_alert2.wav",
		"controller/con_alert3.wav");
}

void Con_PainSound()
{
	if (random() * 6 >= 2) return;
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100,
		"controller/con_pain1.wav", "controller/con_pain2.wav",
		"controller/con_pain3.wav");
}

void Con_AttackSound()
{
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100,
		"controller/con_attack1.wav", "controller/con_attack2.wav",
		"controller/con_attack3.wav");
}

void Con_DeathSound()
{
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100,
		"controller/con_die1.wav", "controller/con_die2.wav");
}

// Anim helpers
float Con_FrameByName(string name)
{
	if (name == "attack1")  return CON_FR_ATTACK1;
	if (name == "attack2")  return CON_FR_ATTACK2;
	if (name == "throw")    return CON_FR_THROW;
	if (name == "idle2")    return CON_FR_IDLE2;
	if (name == "block")    return CON_FR_BLOCK;
	if (name == "shoot")    return CON_FR_SHOOT;
	if (name == "flinch1")  return CON_FR_FLINCH1;
	if (name == "flinch2")  return CON_FR_FLINCH2;
	if (name == "fall")     return CON_FR_FALL;
	if (name == "forward")  return CON_FR_FORWARD;
	if (name == "backward") return CON_FR_BACKWARD;
	if (name == "up")       return CON_FR_UP;
	if (name == "down")     return CON_FR_DOWN;
	if (name == "right")    return CON_FR_RIGHT;
	if (name == "left")     return CON_FR_LEFT;
	if (name == "float")    return CON_FR_FLOAT;
	if (name == "walk")     return CON_FR_WALK;
	if (name == "run")      return CON_FR_RUN;
	if (name == "die1")     return CON_FR_DIE;
	return -1;
}

void Con_PlayFrame(float fr)
{
	if (self.frame == fr) return;
	self.frame      = fr;
	self.frame1time = time;
	self.framerate  = 1;
}

vector Con_HeadPos()
{
	makevectors(self.angles);
	return self.origin + v_forward * 8 + '0 0 60';
}

vector Con_HandPos(float side)
{
	makevectors(self.angles);
	return self.origin + v_forward * 20 + v_right * side * 14 + '0 0 30';
}

void ConZapBall_Touch()
{
	if (other == self.owner) return;
	if (other.solid == SOLID_TRIGGER) return;

	if (other.takedamage)
	{
		entity att = (self.owner != world) ? self.owner : self;
		T_Damage(other, self, att, CON_DMG_BALL, DMG_ENERGYBEAM);
		Sound_Play(self, CHAN_WEAPON, 0.3, ATTN_NORM, 90 + random() * 9, "weapons/electro4.wav");
	}
	remove(self);
}

void ConZapBall_Think()
{
	if (time > self.con_ballDie || vlen(self.velocity) < 10)
	{
		remove(self);
		return;
	}
	self.nextthink = time + 0.1;
}

void Con_FireEnergyBall(vector src, vector dir)
{
	entity ball = spawn();
	ball.classname  = "controller_energy_ball";
	ball.owner      = self;
	ball.movetype   = MOVETYPE_FLY;
	ball.solid      = SOLID_BBOX;
	ball.effects    = EF_ADDITIVE | EF_FULLBRIGHT;
	ball.scale      = 0.5;
	ball.avelocity  = '0 0 0';
	setmodel(ball, CON_BALL_SPRITE);
	setsize(ball, VEC_ORIGIN, VEC_ORIGIN);
	setorigin(ball, src);
	ball.velocity   = dir * CON_BALL_SPEED;
	ball.touch      = ConZapBall_Touch;
	ball.con_ballDie = time + 5;
	ball.think      = ConZapBall_Think;
	ball.nextthink  = time + 0.1;
}

// (CControllerHeadBall)
void ConHeadBall_Die()
{
	remove(self);
}

void ConHeadBall_Touch()
{
	// Bounce: reflect steering accumulator off the surface
	if (other.takedamage) return;   // hunt think handles damage via the zap
	vector dir = normalize(self.con_idealVel);
	float n = -(trace_plane_normal * dir);
	self.con_idealVel = (2 * trace_plane_normal * n + dir) * vlen(self.con_idealVel);
}

void ConHeadBall_Hunt()
{
	self.nextthink = time + 0.1;

	self.alpha = self.alpha - 0.02;

	te_customflash(self.origin, self.alpha * 128, 0.2, '1 1 1');

	entity en = self.enemy;
	if (time > self.con_ballDie || self.alpha < 0.25 || !en || en.health <= 0
		|| self.owner == world)
	{
		self.touch = SUB_Null;
		remove(self);
		return;
	}

	// Accelerate toward the enemy (max 400, +100/tick)
	vector tgt = GetCenter(en);
	float spd = vlen(self.con_idealVel);
	if (spd == 0) self.con_idealVel = self.velocity;
	if (spd > 400) self.con_idealVel = normalize(self.con_idealVel) * 400;
	self.con_idealVel = self.con_idealVel + normalize(tgt - self.origin) * 100;
	self.velocity = self.con_idealVel;

	if (vlen(tgt - self.origin) < 64)
	{
		traceline(self.origin, tgt, FALSE, self);
		entity hit = trace_ent;
		if (hit && hit.takedamage)
		{
			entity att = (self.owner != world) ? self.owner : self;
			T_Damage(hit, self, att, CON_DMG_ZAP, DMG_SHOCK);
		}

		te_lightning2(self, self.origin, trace_endpos);
		Sound_Play(self, CHAN_WEAPON, 0.5, ATTN_NORM, 140 + random() * 20, "weapons/electro4.wav");

		self.velocity  = '0 0 0';
		self.touch     = SUB_Null;
		self.think     = ConHeadBall_Die;
		self.nextthink = time + 0.3;
	}
}

void Con_FireHeadBall()
{
	entity ball = spawn();
	ball.classname  = "controller_head_ball";
	ball.owner      = self;
	ball.enemy      = self.enemy;
	ball.movetype   = MOVETYPE_FLY;
	ball.solid      = SOLID_BBOX;
	ball.effects    = EF_ADDITIVE | EF_FULLBRIGHT;
	ball.scale      = 2.0;
	ball.alpha      = 1.0;
	setmodel(ball, CON_BALL_SPRITE);
	setsize(ball, VEC_ORIGIN, VEC_ORIGIN);
	setorigin(ball, Con_HeadPos());
	ball.velocity   = '0 0 32';
	ball.con_idealVel = '0 0 0';
	ball.con_ballDie = time + 5;
	ball.touch      = ConHeadBall_Touch;
	ball.think      = ConHeadBall_Hunt;
	ball.nextthink  = time + 0.1;
}

// enemy will be, using smoothed velocity estimate, ±2° jitter
vector Con_LeadAim(vector src)
{
	entity en = self.enemy;

	if (IsVisible(en))
		self.con_estVel = self.con_estVel * 0.5 + en.velocity * 0.5;
	else
		self.con_estVel = self.con_estVel * 0.8;

	vector to = GetCenter(en) - src;
	float t = vlen(to) / CON_BALL_SPEED;
	if (t > 10) t = 10;

	vector aim = normalize(to + self.con_estVel * t);
	float delta = 0.0349;   // +-2 degrees
	aim_x = aim_x + (random() * 2 - 1) * delta;
	aim_y = aim_y + (random() * 2 - 1) * delta;
	aim_z = aim_z + (random() * 2 - 1) * delta;
	return normalize(aim);
}

// Hand volley attack (anim attack1/attack2)
// timer ticks at 0.1s. attack2: powerup 17 ticks (25fr @15)
// shoot window 13 ticks (20fr @15), ball every 2 ticks
// attack1 variant: powerup 19, shoot 4.
void Con_VolleyThink()
{
	self.timer = self.timer + 1;
	AI_Face();

	float powerupEnd = (self.frame == CON_FR_ATTACK1) ? 19 : 17;
	float shootTicks = (self.frame == CON_FR_ATTACK1) ? 4  : 13;

	if (self.timer <= powerupEnd)
	{
		// Powerup: pulse the hand glows (replaces attached sprites)
		te_customflash(Con_HandPos(-1), 40, 0.15, CON_GLOW_COLOR);
		te_customflash(Con_HandPos( 1), 40, 0.15, CON_GLOW_COLOR);
	}
	else if (self.timer <= powerupEnd + shootTicks)
	{
		if (self.timer == powerupEnd + 1)
			Con_AttackSound();

		// One ball every other tick, alternating hands
		if (!self.enemy || self.enemy.health <= 0)
		{
			self.think = Con_Run;
			self.nextthink = time + CON_THINK_RATE;
			return;
		}
		if ((self.timer - powerupEnd) & 1)
		{
			self.con_volleyShots = self.con_volleyShots + 1;
			float side = ((self.con_volleyShots & 1) * 2) - 1;
			vector src = Con_HandPos(side);
			Con_FireEnergyBall(src, Con_LeadAim(src));
			te_customflash(src, 48, 0.15, CON_GLOW_COLOR);
		}
	}
	else
	{
		self.attack_finished = time + 2;
		Con_PlayFrame(CON_FR_FORWARD);
		self.think = Con_Run;
		self.nextthink = time + CON_THINK_RATE;
		return;
	}

	self.think = Con_VolleyThink;
	self.nextthink = time + CON_THINK_RATE;
}

void Con_VolleyStart()
{
	self.timer = 0;
	self.con_volleyShots = 0;
	Con_PlayFrame((random() < 0.5) ? CON_FR_ATTACK1 : CON_FR_ATTACK2);
	Con_VolleyThink();
}

// Head ball attack (anim "shoot", 71fr @30fps = 2.37s)
// HEAD_OPEN at frame 28 (~0.9s), BALL_SHOOT at 56 (~1.9s)
void Con_HeadBallThink()
{
	self.timer = self.timer + 1;
	AI_Face();

	if (self.timer >= 9 && self.timer < 19)
	{
		te_customflash(Con_HeadPos(), 40 + self.timer * 4, 0.15, CON_GLOW_COLOR);
	}

	if (self.timer == 19)
	{
		if (self.enemy && self.enemy.health > 0)
			Con_FireHeadBall();
	}

	if (self.timer >= 24)
	{
		self.attack_finished = time + 3;
		Con_PlayFrame(CON_FR_FORWARD);
		self.think = Con_Run;
		self.nextthink = time + CON_THINK_RATE;
		return;
	}

	self.think = Con_HeadBallThink;
	self.nextthink = time + CON_THINK_RATE;
}

void Con_HeadBallStart()
{
	self.timer = 0;
	Con_PlayFrame(CON_FR_SHOOT);
	Con_HeadBallThink();
}

// Attack gate (CheckRangeAttack1/2): volley needs
// 256 < d <= 2048, head ball 64 < d <= 2048
float Con_CheckAttack()
{
	if (!self.enemy) return FALSE;
	if (time < self.attack_finished) return FALSE;
	if (!enemy_infront) return FALSE;	// enemy must be in front (flDot > 0.5 gate, set by AI_Run)

	float d = vlen(GetCenter(self.enemy) - GetCenter(self));
	if (d <= 64 || d > 2048) return FALSE;

	if (d > 256 && random() < 0.65)
		Con_VolleyStart();
	else
		Con_HeadBallStart();
	return TRUE;
}

// Locomotion think chains (Q1 wizard shape)
void Con_Stand()
{
	if (Monster_YieldIfDead()) return;
	Con_PlayFrame(CON_FR_FLOAT);
	self.think     = Con_Stand;
	self.nextthink = time + CON_THINK_RATE;
	Con_IdleSound();
	AI_Stand();
}

void Con_Walk()
{
	if (Monster_YieldIfDead()) return;
	Con_PlayFrame(CON_FR_FLOAT);
	self.think     = Con_Walk;
	self.nextthink = time + CON_THINK_RATE;
	Con_IdleSound();
	AI_Walk(10);
}

void Con_Run()
{
	if (Monster_YieldIfDead()) return;
	if (self.monster_cine && self.monster_cine != world) return;   // scripted sequence owns us
	Con_PlayFrame(CON_FR_FORWARD);
	self.think     = Con_Run;
	self.nextthink = time + CON_THINK_RATE;
	AI_Run(12);
}

// Pain / death
void Con_Pain(entity attacker, float damage)
{
	Con_PainSound();

	if (self.monster_cine && self.monster_cine != world) return;   // scripted sequence owns us

	if (self.pain_finished > time) return;
	self.pain_finished = time + CON_FLINCH_DELAY;

	Con_PlayFrame((damage > 20) ? CON_FR_FLINCH2 : CON_FR_FLINCH1);
	self.think     = Con_Run;
	self.nextthink = time + ((damage > 20) ? 0.9 : 0.45);
}

void Con_DieLand()
{
	// Corpse settled
	self.solid = SOLID_CORPSE;
	setsize(self, '-32 -32 0', '32 32 16');
	self.think = SUB_Null;
	self.nextthink = 0;
}

void Con_Die()
{
	if (self.health < GIB_HEALTH_VALUE)
	{
		Gib();
		return;
	}

	Con_DeathSound();

	// Flying monster falls out of the air
	self.velocity_z  = self.velocity_z + 60;
	self.flags       = self.flags - (self.flags & FL_ONGROUND);
	self.flags       = self.flags - (self.flags & FL_FLY);
	self.movetype    = MOVETYPE_TOSS;
	self.takedamage  = DAMAGE_NO;

	Con_PlayFrame(CON_FR_DIE);   // 51fr @20 = 2.55s
	self.think     = Con_DieLand;
	self.nextthink = time + 2.55;
}

void Con_Precache()
{
	precache_model(CON_MODEL);
	precache_model(CON_BALL_SPRITE);

	precache_sound("controller/con_attack1.wav");
	precache_sound("controller/con_attack2.wav");
	precache_sound("controller/con_attack3.wav");
	precache_sound("controller/con_idle1.wav");
	precache_sound("controller/con_idle2.wav");
	precache_sound("controller/con_idle3.wav");
	precache_sound("controller/con_idle4.wav");
	precache_sound("controller/con_idle5.wav");
	precache_sound("controller/con_alert1.wav");
	precache_sound("controller/con_alert2.wav");
	precache_sound("controller/con_alert3.wav");
	precache_sound("controller/con_pain1.wav");
	precache_sound("controller/con_pain2.wav");
	precache_sound("controller/con_pain3.wav");
	precache_sound("controller/con_die1.wav");
	precache_sound("controller/con_die2.wav");
	precache_sound("weapons/electro4.wav");
}

void monster_alien_controller()
{
	if (Monster_RemoveIfSpent()) return;
	if (RemoveInDeathmatch()) return;

	Con_Precache();

	self.solid      = SOLID_SLIDEBOX;
	self.movetype   = MOVETYPE_FLY;
	self.yaw_speed  = YAW_HL(120);	// Sets yaw speed
	self.health     = CON_HEALTH;
	self.max_health = self.health;
	// view_ofs: FlyMonster_StartGo sets '0 0 25' (mid-body; used -2).
	self.monster_bloodColor    = BLOOD_COLOR_GREEN;
	self.monster_fieldOfView = -1;

	setmodel(self, CON_MODEL);
	setsize(self, '-32 -32 0', '32 32 64');

	self.th_stand    = Con_Stand;
	self.th_walk     = Con_Walk;
	self.th_run      = Con_Run;
	self.th_pain     = Con_Pain;
	self.th_die      = Con_Die;
	self.checkAttack = Con_CheckAttack;
	self.sightSound  = Con_AlertSound;
	self.frameByName = Con_FrameByName;

	Monster_InitTakeDamage();
	FlyMonster_Start();
}
