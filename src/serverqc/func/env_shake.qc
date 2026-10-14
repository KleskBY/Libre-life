// self.scale is amplitude
// self.dmg is radius

#define SF_SHAKE_EVERYONE	0x0001
#define SF_SHAKE_DISRUPT	0x0002		// TODO: Disrupt controls
#define SF_SHAKE_INAIR		0x0004		// TODO: Shake players in air

.float amplitude;
.float frequency;
.float duration;


void Shaker_Think()
{
	float left = self.timer - time;

	entity p = findradius(self.origin, self.radius);
	while(p)
	{
		if (p.flags & FL_CLIENT)
		{
			float factor = self.dmg * left; //* self.wait;
			p.punchvector = p.punchvector + (randomvec() * factor);
			p.punchangle = p.punchangle + (randomvec() * factor * 0.1);
			if (time > self.timer) p.punchvector = '0 0 0';
		}

		p = p.chain;
	}
	if (time > self.timer)
	{
		remove(self);
		return;
	}
	self.nextthink = time + 0.1;
};


void(vector center, float amplitude, float frequency, float duration, float rad) EnvShake_ScreenShake =
{
    entity s;

    if (duration <= 0 || amplitude <= 0)
        return;

    s = spawn();
    s.classname = "screenshake";
	s.wait = frequency;
    s.radius = rad * 1.25;
    s.timer = time + duration * 0.75;
	s.dmg = amplitude;
	setorigin(s, center);
    s.think = Shaker_Think;
    s.nextthink = time + 0.1;
};

void Shake_Use()
{
	EnvShake_ScreenShake(self.origin, self.amplitude, self.frequency, self.duration, self.radius);
}

void Shake_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	EnvShake_ScreenShake(self.origin, self.amplitude, self.frequency, self.duration, self.radius);
}

void env_shake()
{
	self.solid			= SOLID_NOT;
	self.movetype		= MOVETYPE_NONE;
	self.effects		= 0;
	self.frame			= 0;

	if (self.spawnflags & SF_SHAKE_EVERYONE)
		self.dmg = 0;

	self.use = Shake_Use;
	self.usehl = Shake_UseHL;
}
