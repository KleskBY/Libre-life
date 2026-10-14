
void EnvBeverage_Precache()
{
	precache_model("models/can.iqm");
	precache_sound("weapons/g_bounce3.wav");
}

void EnvBeverage_Use(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	if (self.frags != 0 || self.health <= 0)
	{
		return;
	}

	entity pCan = Entity_Create(item_sodacan, self.origin, self.angles, self);
	if (self.skin == 6)
	{
		pCan.skin = Math_RandomInt(0, 5); // random
	}
	else
	{
		pCan.skin = self.skin;
	}

	self.frags = 1;
	self.health = self.health - 1;
}

void EnvBeverage_UseLegacy()
{
	EnvBeverage_Use(activator, activator, USE_TOGGLE, 0);
}

void env_beverage()
{
	EnvBeverage_Precache();
	self.solid = SOLID_NOT;
	self.effects = EF_NODRAW;
	self.frags = 0;

	if (!self.health)
	{
		self.health = 10;
	}

	self.use   = EnvBeverage_UseLegacy;
	self.usehl = EnvBeverage_Use;
}