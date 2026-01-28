// self.scale is amplitude
// self.dmg_save is frequency
// self.dmg_take is duration
// self.dmg is radius
// radius of 0 means all players
// NOTE: UTIL_ScreenShake() will only shake players who are on the ground

#define SF_SHAKE_EVERYONE	0x0001		// Don't check radius
// UNDONE: These don't work yet
#define SF_SHAKE_DISRUPT	0x0002		// Disrupt controls
#define SF_SHAKE_INAIR		0x0004		// Shake players in air

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
			float factor = self.dmg * left;//* self.wait;
			p.punchvector = p.punchvector + (randomvec() * factor);
			p.punchangle = p.punchangle + (randomvec() * factor * 0.1);
			// p.punchangle = randomvec() * factor;
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


void(vector center, float amplitude, float frequency, float duration, float rad) UTIL_ScreenShake =
{
    entity s;

    if (duration <= 0 || amplitude <= 0)
        return;

    s = spawn();
    s.classname = "screenshake";
	s.wait = frequency;
    s.radius = rad;
    s.timer = time + duration * 0.75;
	s.dmg = amplitude;
	setorigin(s, center);
    s.think = Shaker_Think;
    s.nextthink = time + 0.1;
};

void Shake_Use()
{
	UTIL_ScreenShake(self.origin, self.amplitude, self.frequency, self.duration, self.radius);
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
}
