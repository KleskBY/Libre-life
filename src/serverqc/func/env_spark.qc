
void EnvSpark_Think()
{
	float interval = self.delay ? self.delay : 0.75;
	DoSpark(self.origin);
	self.nextthink = time + random(interval * 0.5, interval * 1.5);
}

void EnvSpark_Use()
{
	if (self.think == EnvSpark_Think)
	{
		self.think     = SUB_Null;
		self.nextthink = -1;
	}
	else
	{
		self.think     = EnvSpark_Think;
		self.nextthink = time + random(0, self.delay ? self.delay : 0.75);
	}
}

void EnvSpark_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	if (self.think == EnvSpark_Think)
	{
		self.think     = SUB_Null;
		self.nextthink = -1;
	}
	else
	{
		self.think     = EnvSpark_Think;
		self.nextthink = time + random(0, self.delay ? self.delay : 0.75);
	}
}

void env_spark()
{
	self.solid    = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.use      = EnvSpark_Use;
	self.usehl    = EnvSpark_UseHL;

	if (!(self.spawnflags & 1))
	{
		self.think     = EnvSpark_Think;
		self.nextthink = time + random(0, self.delay ? self.delay : 0.75);
	}
}
