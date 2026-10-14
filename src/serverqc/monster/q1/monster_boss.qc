
#define BOSS_FRAME_RISE1     0
#define BOSS_FRAME_RISE17    16
#define BOSS_FRAME_WALK1     17
#define BOSS_FRAME_WALK31    47
#define BOSS_FRAME_DEATH1    48
#define BOSS_FRAME_DEATH9    56
#define BOSS_FRAME_ATTACK1   57
#define BOSS_FRAME_ATTACK23  79
#define BOSS_FRAME_SHOCKA1   80
#define BOSS_FRAME_SHOCKA10  89
#define BOSS_FRAME_SHOCKB1   90
#define BOSS_FRAME_SHOCKB6   95
#define BOSS_FRAME_SHOCKC1   96
#define BOSS_FRAME_SHOCKC10  105


#define BOSS_SND_OUT      "boss1/out1.wav"
#define BOSS_SND_SIGHT    "boss1/sight1.wav"
#define BOSS_SND_THROW    "boss1/throw.wav"
#define BOSS_SND_PAIN     "boss1/pain.wav"
#define BOSS_SND_DEATH    "boss1/death.wav"

#define BOSS_LAVABALL_MDL "progs/lavaball.mdl"
#define BOSS_MISSILE_DMG    120
#define BOSS_MISSILE_RADIUS 200

void Boss_Rise();
void Boss_Idle();
void Boss_Attack();
void Boss_Die();
void Boss_ShockA();
void Boss_ShockB();
void Boss_ShockC();

void Boss_Face()
{
	if (!self.enemy || self.enemy.health <= 0 || random() < 0.02)
	{
		self.enemy = find(self.enemy, classname, "player");
		if (!self.enemy)
			self.enemy = find(world, classname, "player");
	}
	if (self.enemy) AI_Face();
}

void Boss_Rise()
{
	if (self.frame == BOSS_FRAME_RISE1)
		Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, BOSS_SND_OUT);
	else if (self.frame == BOSS_FRAME_RISE1 + 1)
		Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, BOSS_SND_SIGHT);

	self.frame = self.frame + 1;

	if (self.frame > BOSS_FRAME_RISE17)
	{
		self.frame     = BOSS_FRAME_ATTACK1;
		self.think     = Boss_Attack;
		self.nextthink = time + 0.1;
		return;
	}

	self.think     = Boss_Rise;
	self.nextthink = time + 0.1;
}


void Boss_Idle()
{
	Boss_Face();

	self.frame = self.frame + 1;
	if (self.frame < BOSS_FRAME_WALK1 || self.frame > BOSS_FRAME_WALK31)
		self.frame = BOSS_FRAME_WALK1;

	if (self.enemy && self.enemy.health > 0)
	{
		self.frame     = BOSS_FRAME_ATTACK1;
		self.think     = Boss_Attack;
		self.nextthink = time + 0.1;
		return;
	}

	self.think     = Boss_Idle;
	self.nextthink = time + 0.1;
}


void Boss_LavaBall_Touch()
{
	if (other == self.owner) return;
	if (other.solid == SOLID_TRIGGER) return;

	T_RadiusDamage(self, self.owner, BOSS_MISSILE_DMG, BOSS_MISSILE_RADIUS, DMG_BLAST | DMG_ALWAYSGIB);
	te_explosion(self.origin);
	Sound_Play(self, CHAN_WEAPON, 1, Sound_Radius(2000), PITCH_NORM, "weapons/explode3.wav");
	remove(self);
}

void Boss_FireMissile(vector p)
{
	if (!self.enemy || self.enemy.health <= 0) return;

	vector offang = vectoangles(self.enemy.origin - self.origin);
	makevectors(offang);

	vector org = self.origin + p_x * v_forward + p_y * v_right + p_z * '0 0 1';

	vector d;
	if (skill > 1)
	{
		float t = vlen(self.enemy.origin - org) / 300;
		vector vel = self.enemy.velocity;
		vel_z = 0;
		d = self.enemy.origin + t * vel;
	}
	else
	{
		d = self.enemy.origin;
	}

	vector dir = normalize(d - org);

	entity mis      = spawn();
	mis.owner       = self;
	mis.movetype    = MOVETYPE_FLYMISSILE;
	mis.solid       = SOLID_BBOX;
	mis.touch       = Boss_LavaBall_Touch;
	mis.think       = SUB_Remove;
	mis.nextthink   = time + 10;
	setmodel(mis, BOSS_LAVABALL_MDL);
	mis.avelocity   = '200 100 300';
	mis.velocity    = dir * 300;
	mis.angles      = vectoangles(dir);
	setsize(mis, VEC_ORIGIN, VEC_ORIGIN);
	setorigin(mis, org);

	Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, BOSS_SND_THROW);
}

void Boss_Attack()
{
	Boss_Face();

	// Fire at attack9 (step 8) and attack20 (step 19), 0-indexed
	float atk_step = self.frame - BOSS_FRAME_ATTACK1;
	if (atk_step == 8)  Boss_FireMissile('100  100 200');
	if (atk_step == 19) Boss_FireMissile('100 -100 200');

	self.frame = self.frame + 1;
	if (self.frame > BOSS_FRAME_ATTACK23)
		self.frame = BOSS_FRAME_ATTACK1;

	if (!self.enemy || self.enemy.health <= 0)
	{
		self.frame     = BOSS_FRAME_WALK1;
		self.think     = Boss_Idle;
		self.nextthink = time + 0.1;
		return;
	}

	self.think     = Boss_Attack;
	self.nextthink = time + 0.1;
}

// self.timer is used as the local step counter

void Boss_ShockA()
{
	self.frame = BOSS_FRAME_SHOCKA1 + self.timer;
	self.timer = self.timer + 1;

	if (self.timer >= 10)
	{
		self.timer     = 0;
		self.frame     = BOSS_FRAME_ATTACK1;
		self.think     = Boss_Attack;
		self.nextthink = time + 0.1;
		return;
	}

	self.think     = Boss_ShockA;
	self.nextthink = time + 0.1;
}

void Boss_ShockB()
{
	if (self.timer < 6)
		self.frame = BOSS_FRAME_SHOCKB1 + self.timer;
	else
		self.frame = BOSS_FRAME_SHOCKB1 + (self.timer - 6);

	self.timer = self.timer + 1;

	if (self.timer >= 10)
	{
		self.timer     = 0;
		self.frame     = BOSS_FRAME_ATTACK1;
		self.think     = Boss_Attack;
		self.nextthink = time + 0.1;
		return;
	}

	self.think     = Boss_ShockB;
	self.nextthink = time + 0.1;
}

void Boss_ShockC()
{
	self.frame = BOSS_FRAME_SHOCKC1 + self.timer;
	self.timer = self.timer + 1;

	if (self.timer >= 10)
	{
		self.timer = 0;
		Boss_Die();
		return;
	}

	self.think     = Boss_ShockC;
	self.nextthink = time + 0.1;
}

void Boss_DieThink()
{
	if (self.timer >= 9)
	{
		killed_monsters = killed_monsters + 1;
		WriteByte(MSG_ALL, SVC_KILLEDMONSTER);
		monster_death_use();
		remove(self);
		return;
	}

	self.frame = BOSS_FRAME_DEATH1 + self.timer;

	if (self.timer == 0)
		Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, BOSS_SND_DEATH);
	else if (self.timer == 8)
	{
		Sound_Play(self, CHAN_BODY, 1, ATTN_NORM, PITCH_NORM, BOSS_SND_OUT);
		te_lavasplash(self.origin);
	}

	self.timer     = self.timer + 1;
	self.think     = Boss_DieThink;
	self.nextthink = time + 0.1;
}

void Boss_Die()
{
	self.solid     = SOLID_NOT;
	self.takedamage = DAMAGE_NO;
	self.timer     = 0;
	self.frame     = BOSS_FRAME_DEATH1;
	Boss_DieThink();
}

void Boss_Awake()
{
	self.solid    = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;
	self.takedamage = DAMAGE_NO;

	setmodel(self, "progs/boss.mdl");
	setsize(self, '-128 -128 -24', '128 128 256');

	self.health = (skill == 0) ? 1 : 3;

	self.enemy = activator;
	if (!self.enemy || self.enemy.classname != "player")
		self.enemy = find(world, classname, "player");

	self.yaw_speed = 20;
	te_lavasplash(self.origin);

	self.frame = BOSS_FRAME_RISE1;
	Boss_Rise();
}

void Boss_AwakeHL(entity pActivator, entity pCaller, float utype, float uvalue)
{
	activator = pActivator;
	Boss_Awake();
}

void monster_boss()
{
    self.q1_monster = TRUE;
	if (Monster_RemoveIfSpent()) return;
	if(RemoveInDeathmatch()) return;

	precache_model("progs/boss.mdl");
	precache_model(BOSS_LAVABALL_MDL);

	precache_sound(BOSS_SND_OUT);
	precache_sound(BOSS_SND_SIGHT);
	precache_sound(BOSS_SND_THROW);
	precache_sound(BOSS_SND_PAIN);
	precache_sound(BOSS_SND_DEATH);
	precache_sound("misc/power.wav");
	precache_sound("weapons/explode3.wav");

	total_monsters = total_monsters + 1;

	self.solid    = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.use      = Boss_Awake;
	self.usehl    = Boss_AwakeHL;
}


entity le1, le2;
float  lightning_end;

void lightning_fire()
{
	if (time >= lightning_end)
	{
		entity saved = self;
		self = le1; Door_DoorGoDown();
		self = le2; Door_DoorGoDown();
		self = saved;
		return;
	}

	vector p1 = (le1.mins + le1.maxs) * 0.5;
	p1_z = le1.absmin_z + 8;

	vector p2 = (le2.mins + le2.maxs) * 0.5;
	p2_z = le2.absmin_z + 8;

	// Shorten bolt by 100

	self.nextthink = time + 0.1;
	self.think     = lightning_fire;

	te_lightning1(world, p1, p2);
}

void lightning_use()
{
	if (lightning_end >= time + 1) return;

	le1 = find(world, target, "lightning");
	le2 = find(le1,   target, "lightning");
	if (!le1 || !le2)
	{
		dprint("event_lightning: missing electrode targets\n");
		return;
	}

	if ((le1.state != STATE_TOP && le1.state != STATE_BOTTOM)
		|| (le2.state != STATE_TOP && le2.state != STATE_BOTTOM)
		|| (le1.state != le2.state))
		return;

	le1.nextthink = -1;
	le2.nextthink = -1;
	lightning_end = time + 1;

	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, "misc/power.wav");
	lightning_fire();

	if (le1.state != STATE_TOP) return;

	entity boss = find(world, classname, "monster_boss");
	if (!boss || boss.health <= 0) return;

	entity old = self;
	self = boss;
	self.enemy = activator;

	if (self.health > 0)
	{
		Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, BOSS_SND_PAIN);
		self.health = self.health - 1;
		self.timer  = 0;

		if      (self.health >= 2) Boss_ShockA();
		else if (self.health == 1) Boss_ShockB();
		else                       Boss_ShockC();
	}

	self = old;
}

void Lightning_UseHL(entity pActivator, entity pCaller, float utype, float uvalue)
{
	activator = pActivator;
	lightning_use();
}

void event_lightning()
{
	self.use   = lightning_use;
	self.usehl = Lightning_UseHL;
}
