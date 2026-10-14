
#define SF_BLOOD_RANDOM            0x0001
#define SF_BLOOD_STREAM            0x0002
#define SF_BLOOD_PLAYER            0x0004
#define SF_BLOOD_DECAL             0x0008

#define BLOOD_COLOR_RED            GIB_BLOOD_RED
#define BLOOD_COLOR_YELLOW         GIB_BLOOD_ALIEN


float EnvBlood_Color()        { return self.impulse; }
float EnvBlood_Amount()       { return self.dmg; }

vector EnvBlood_Direction()
{
	if (self.spawnflags & SF_BLOOD_RANDOM)
	{
		vector v = [random(-1, 1), random(-1, 1), random(0, 1)];
		if (vlen(v) <= 0) v = '0 0 1';
		return normalize(v);
	}
	return self.movedir;
}

vector EnvBlood_Position(entity pActivator)
{
	if (self.spawnflags & SF_BLOOD_PLAYER)
	{
		entity p = (pActivator && pActivator.classname == "player")
		         ? pActivator
		         : find(world, classname, "player");
		if (p)
			return p.origin + p.view_ofs +
			       [random(-10, 10), random(-10, 10), random(-10, 10)];
	}
	return self.origin;
}

void EnvBlood_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	vector pos  = EnvBlood_Position(pActivator);
	vector dir  = EnvBlood_Direction();
	float  amt  = EnvBlood_Amount();
	float  col  = EnvBlood_Color();

	if (self.spawnflags & SF_BLOOD_STREAM)
		Blood_SpawnImpact(pos, dir, col, amt * 2);
	else
		Blood_SpawnImpact(pos, dir, col, amt);

	if (self.spawnflags & SF_BLOOD_DECAL)
	{
		vector tEnd = pos + dir * amt * 2;
		traceline(pos, tEnd, TRUE, self);
		if (trace_fraction < 1)
			Blood_SpawnImpact(trace_endpos + trace_plane_normal * 2,
			                  trace_plane_normal, col, amt);
	}
}

void EnvBlood_Use()
{
	EnvBlood_UseHL(activator, self, useType, 0);
}

void env_blood()
{
	self.solid    = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.effects  = 0;
	self.frame    = 0;

	for (float i = 1; i < (tokenize(__fullspawndata) - 1); i += 2)
	{
		string key = argv(i);
		string val = argv(i + 1);
		if (key == "color")
		{
			float c = stof(val);
			self.impulse = (c == 1) ? BLOOD_COLOR_YELLOW : BLOOD_COLOR_RED;
		}
	}
	if (self.amount > 0)   self.dmg = self.amount;
	if (self.impulse == 0) self.impulse = BLOOD_COLOR_RED;
	if (self.dmg <= 0)     self.dmg = 50;

	if (self.angles != '0 0 0') SetMovedir();

	self.use   = EnvBlood_Use;
	self.usehl = EnvBlood_UseHL;
}
