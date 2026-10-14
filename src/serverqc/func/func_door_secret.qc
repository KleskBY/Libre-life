
#define SECRET_OPEN_ONCE	1
#define SECRET_1ST_LEFT		2
#define SECRET_1ST_DOWN		4
#define SECRET_NO_SHOOT		8
#define SECRET_YES_SHOOT	16

void Id1Secret_Move1();
void Id1Secret_Move2();
void Id1Secret_Move3();
void Id1Secret_Move4();
void Id1Secret_Move5();
void Id1Secret_Move6();
void Id1Secret_Done();

void Id1Secret_Use()
{
	float temp;

	self.health = 10000;
	if (self.origin != self.oldorigin)
		return;

	self.message = "";
	SUB_UseTargets();

	if (!(self.spawnflags & SECRET_NO_SHOOT))
	{
		self.th_pain = SUB_null_pain;
		self.takedamage = DAMAGE_NO;
	}
	self.velocity = '0 0 0';

	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, self.noise1);
	self.nextthink = self.ltime + 0.1;

	temp = 1 - (self.spawnflags & SECRET_1ST_LEFT);
	makevectors(self.mangle);

	if (!self.t_width)
	{
		if (self.spawnflags & SECRET_1ST_DOWN)
			self.t_width = fabs(v_up * self.size);
		else
			self.t_width = fabs(v_right * self.size);
	}

	if (!self.t_length)
		self.t_length = fabs(v_forward * self.size);

	if (self.spawnflags & SECRET_1ST_DOWN)
		self.dest1 = self.origin - v_up * self.t_width;
	else
		self.dest1 = self.origin + v_right * (self.t_width * temp);

	self.dest2 = self.dest1 + v_forward * self.t_length;
	SUB_CalcMove(self.dest1, self.speed, Id1Secret_Move1);
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, self.noise2);
}

void Id1Secret_Pain(entity attacker, float damage)
{
	Id1Secret_Use();
}

void Id1Secret_Move1()
{
	self.nextthink = self.ltime + 1.0;
	self.think = Id1Secret_Move2;
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, self.noise3);
}

void Id1Secret_Move2()
{
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, self.noise2);
	SUB_CalcMove(self.dest2, self.speed, Id1Secret_Move3);
}

void Id1Secret_Move3()
{
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, self.noise3);
	if (!(self.spawnflags & SECRET_OPEN_ONCE))
	{
		self.nextthink = self.ltime + self.wait;
		self.think = Id1Secret_Move4;
	}
}

void Id1Secret_Move4()
{
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, self.noise2);
	SUB_CalcMove(self.dest1, self.speed, Id1Secret_Move5);
}

void Id1Secret_Move5()
{
	self.nextthink = self.ltime + 1.0;
	self.think = Id1Secret_Move6;
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, self.noise3);
}

void Id1Secret_Move6()
{
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, self.noise2);
	SUB_CalcMove(self.oldorigin, self.speed, Id1Secret_Done);
}

void Id1Secret_Done()
{
	if (!self.targetname || (self.spawnflags & SECRET_YES_SHOOT))
	{
		self.health = 10000;
		self.takedamage = DAMAGE_YES;
		self.th_pain = Id1Secret_Pain;
	}
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, self.noise3);
}

void Id1Secret_Blocked()
{
	if (time < self.attack_finished)
		return;
	self.attack_finished = time + 0.5;
	T_Damage(other, self, self, self.dmg, DMG_CRUSH);
}

void Id1Secret_Touch()
{
	if (other.classname != "player")
		return;
	if (self.attack_finished > time)
		return;

	self.attack_finished = time + 2;

	if (self.message)
	{
		centerprint(other, self.message);
		Sound_Play(other, CHAN_BODY, 1, ATTN_NORM, PITCH_NORM, "misc/talk.wav");
	}
}

void Id1Secret_Precache()
{
	if (self.sounds == 0)
		self.sounds = 3;
	if (self.sounds == 1)
	{
		precache_sound("doors/latch2.wav");
		precache_sound("doors/winch2.wav");
		precache_sound("doors/drclos4.wav");
		self.noise1 = "doors/latch2.wav";
		self.noise2 = "doors/winch2.wav";
		self.noise3 = "doors/drclos4.wav";
	}
	else if (self.sounds == 2)
	{
		precache_sound("doors/airdoor1.wav");
		precache_sound("doors/airdoor2.wav");
		self.noise2 = "doors/airdoor1.wav";
		self.noise1 = "doors/airdoor2.wav";
		self.noise3 = "doors/airdoor2.wav";
	}
	else
	{
		precache_sound("doors/basesec1.wav");
		precache_sound("doors/basesec2.wav");
		self.noise2 = "doors/basesec1.wav";
		self.noise1 = "doors/basesec2.wav";
		self.noise3 = "doors/basesec2.wav";
	}
}

void func_door_secret()
{
	if (!Map_IsId1BSP())
	{
		remove(self);
		return;
	}

	Id1Secret_Precache();
	if (!self.dmg)
		self.dmg = 2;

	self.mangle = self.angles;
	self.angles = '0 0 0';
	self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_PUSH;
	setmodel(self, self.model);
	setorigin(self, self.origin);
	Render_Apply(self);

	self.touch = Id1Secret_Touch;
	self.blocked = Id1Secret_Blocked;
	self.speed = 50;
	self.use = Id1Secret_Use;
	self.usehl = __NULL__;

	if (!self.targetname || (self.spawnflags & SECRET_YES_SHOOT))
	{
		self.health = 10000;
		self.takedamage = DAMAGE_YES;
		self.th_pain = Id1Secret_Pain;
		self.th_die = Id1Secret_Use;
	}

	self.oldorigin = self.origin;
	if (!self.wait)
		self.wait = 5;
}
