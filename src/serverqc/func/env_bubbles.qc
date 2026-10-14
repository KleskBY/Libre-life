
#define SF_BUBBLES_STARTOFF        0x0001

#define BUBBLE_SPRITE_PATH         "sprites/bubble.spr"
#define BUBBLE_RISE_SPEED          80
#define BUBBLE_LIFETIME            3.0

.float density;
.float frequency;
.float current;

void Bubble_Think()
{
	float pc = pointcontents(self.origin);
	if (pc != CONTENT_WATER && pc != CONTENT_SLIME)
	{
		remove(self);
		return;
	}
	if (time >= self.timer)
	{
		remove(self);
		return;
	}
	self.think = Bubble_Think;
	self.nextthink = time + 0.05;
}

void Bubble_Spawn(vector mn, vector mx, float currentSpeed)
{
	entity b = spawn();
	b.classname = "env_bubbles_particle";
	b.solid     = SOLID_NOT;
	b.movetype  = MOVETYPE_NOCLIP;
	b.effects   = EF_ADDITIVE;

	setmodel(b, BUBBLE_SPRITE_PATH);

	vector org = [mn_x + random() * (mx_x - mn_x),
	              mn_y + random() * (mx_y - mn_y),
	              mn_z + random() * (mx_z - mn_z)];
	setorigin(b, org);

	float ang = random() * 360;
	vector drift = [cos(ang * M_PI / 180) * currentSpeed,
	                sin(ang * M_PI / 180) * currentSpeed,
	                0];
	b.velocity = drift + [0, 0, BUBBLE_RISE_SPEED];

	b.timer     = time + BUBBLE_LIFETIME;   // hard cap (deep water)
	b.think     = Bubble_Think;
	b.nextthink = time + 0.05;
}

void EnvBubbles_FizzThink()
{
	float count = self.density;
	if (count < 1) count = 1;

	for (float i = 0; i < count; i = i + 1)
		Bubble_Spawn(self.absmin, self.absmax, self.current);

	float freq = self.frequency;
	if (freq > 19) self.nextthink = time + 0.5;
	else           self.nextthink = time + 2.5 - (0.1 * freq);
}

void EnvBubbles_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	useType = useTypeArg;
	if (ShouldToggle(self.state))
		self.state = !self.state;

	if (self.state)
	{
		self.think     = EnvBubbles_FizzThink;
		self.nextthink = time + 0.1;
	}
	else
	{
		self.think     = SUB_Null;
		self.nextthink = -1;
	}
}

void EnvBubbles_Use()
{
	EnvBubbles_UseHL(activator, self, useType, 0);
}

void env_bubbles()
{
	precache_model(BUBBLE_SPRITE_PATH);

	setmodel(self, self.model);
	self.solid     = SOLID_NOT;
	self.movetype  = MOVETYPE_NONE;
	self.modelindex = 0;
	self.model     = "";

	if (self.density < 1)   self.density = 1;
	if (self.frequency < 1) self.frequency = 1;

	self.use   = EnvBubbles_Use;
	self.usehl = EnvBubbles_UseHL;

	if (!(self.spawnflags & SF_BUBBLES_STARTOFF))
	{
		self.state     = 1;
		self.think     = EnvBubbles_FizzThink;
		self.nextthink = time + 2.0;
	}
	else
	{
		self.state = 0;
	}
}
