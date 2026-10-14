// shockwave <x> <y> <z> <radius> <duration>
.float wave_birth;
.float wave_radius;
.float wave_duration;

void Shockwave_Think()
{
	float elapsed = time - self.wave_birth;
	float frac = elapsed / self.wave_duration;
	if (frac > 1) frac = 1;
	float rad = self.wave_radius * frac;

	float pef;
	if (elapsed >= self.wave_duration) pef = particleeffectnum("PEF_SHOCKWAVE_END");
	else                               pef = particleeffectnum("PEF_SHOCKWAVE");

	float spacing = 250 / rad;
	if (spacing < 3) spacing = 3;

	vector org;
	org_z = self.origin_z + 8;
	float a;
	for (a = 0; a < 360; a = a + spacing)
	{
		org_x = self.origin_x + sin(a * DEG2RAD) * rad;
		org_y = self.origin_y + cos(a * DEG2RAD) * rad;
		pointparticles(pef, org, normalize(org - self.origin), 1);
	}

	if (elapsed >= self.wave_duration)
	{
		remove(self);
		return;
	}
	self.think = Shockwave_Think;
	self.nextthink = time;
}

float Shockwave_Parse()
{
	entity w = spawn();
	w.classname     = "cl_shockwave";
	w.origin        = [stof(argv(1)), stof(argv(2)), stof(argv(3))];
	w.wave_radius   = stof(argv(4));
	w.wave_duration = stof(argv(5));
	if (w.wave_duration <= 0) w.wave_duration = 0.4;
	w.wave_birth    = time;
	w.think         = Shockwave_Think;
	w.nextthink     = time;
	return TRUE;
}
