
float START_OFF = 1;

void light_use()
{
	if (self.spawnflags & START_OFF)
	{
		lightstyle(self.style, "m");
		self.spawnflags = self.spawnflags - START_OFF;
	}
	else
	{
		lightstyle(self.style, "a");
		self.spawnflags = self.spawnflags + START_OFF;
	}
};

void light()
{
	if (!self.targetname) // inert light
	{	
		remove(self);
		return;
	}
	
	if (self.style >= 32)
	{
		self.use = light_use;
		if (self.spawnflags & START_OFF) lightstyle(self.style, "a");
		else lightstyle(self.style, "m");
	}
};

void light_fluoro()
{
	if (self.style >= 32)
	{
		self.use = light_use;
		if (self.spawnflags & START_OFF) lightstyle(self.style, "a");
		else lightstyle(self.style, "m");
	}
};

void light_spot()
{
	light();
}