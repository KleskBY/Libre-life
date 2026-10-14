
float START_OFF = 1;

void Light_Use()
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

// Use: toggles lightstyle on/off via spawnflag bit. Params unused.
void Light_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
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
		self.use = Light_Use;
		self.usehl = Light_UseHL;
		if (self.spawnflags & START_OFF) lightstyle(self.style, "a");
		else lightstyle(self.style, "m");
	}
};

void light_fluoro()
{
	if (self.style >= 32)
	{
		self.use = Light_Use;
		self.usehl = Light_UseHL;
		if (self.spawnflags & START_OFF) lightstyle(self.style, "a");
		else lightstyle(self.style, "m");
	}
};

void light_spot()
{
	light();
}


/*QUAKED light_fluorospark (0 1 0) (-8 -8 -8) (8 8 8)
Non-displayed light.
Default light value is 300
Default style is 10
Makes sparking, broken fluorescent sound
*/
void() light_fluorospark =
{
	if (!self.style)
		self.style = 10;

	precache_sound("ambience/buzz1.wav");
	ambientsound(self.origin, "ambience/buzz1.wav", 0.5, ATTN_STATIC);
};

/*QUAKED light_globe (0 1 0) (-8 -8 -8) (8 8 8)
Sphere globe light.
Default light value is 300
Default style is 0
*/
void() light_globe =
{
	precache_model("progs/s_light.spr");
	setmodel(self, "progs/s_light.spr");
	self.effects = self.effects | EF_ADDITIVE;
	makestatic(self);
};

void() FireAmbient =
{
	precache_sound("ambience/fire1.wav");
	ambientsound(self.origin, "ambience/fire1.wav", 0.5, ATTN_STATIC);
};

/*QUAKED light_torch_small_walltorch (0 .5 0) (-10 -10 -20) (10 10 20)
Short wall torch
Default light value is 200
Default style is 0
*/
void() light_torch_small_walltorch =
{
	precache_model("progs/flame.mdl");
	setmodel(self, "progs/flame.mdl");
	FireAmbient();
	makestatic(self);
};

/*QUAKED light_flame_large_yellow (0 1 0) (-10 -10 -12) (12 12 18)
Large yellow flame ball
*/
void() light_flame_large_yellow =
{
	precache_model("progs/flame2.mdl");
	setmodel(self, "progs/flame2.mdl");
	self.frame = 1;
	FireAmbient();
	makestatic(self);
};

/*QUAKED light_flame_small_yellow (0 1 0) (-8 -8 -8) (8 8 8) START_OFF
Small yellow flame ball
*/
void() light_flame_small_yellow =
{
	precache_model("progs/flame2.mdl");
	setmodel(self, "progs/flame2.mdl");
	FireAmbient();
	makestatic(self);
};

/*QUAKED light_flame_small_white (0 1 0) (-10 -10 -40) (10 10 40) START_OFF
Small white flame ball
*/
void() light_flame_small_white =
{
	precache_model("progs/flame2.mdl");
	setmodel(self, "progs/flame2.mdl");
	FireAmbient();
	makestatic(self);
};