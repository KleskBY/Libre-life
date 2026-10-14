#define SPAWNFLAG_NOMESSAGE	1
#define SPAWNFLAG_NOTOUCH	1
#define SPAWNFLAG_DROIDONLY	4

void Trigger_CounterUse()
{
	self.count = self.count - 1;
	if (self.count < 0) return;

	if (self.count != 0)
	{
		if (activator.classname == "player" && (self.spawnflags & SPAWNFLAG_NOMESSAGE) == 0)
		{
			if (self.count >= 4)
				centerprint (activator, "There are more to go...");
			else if (self.count == 3)
				centerprint (activator, "Only 3 more to go...");
			else if (self.count == 2)
				centerprint (activator, "Only 2 more to go...");
			else
				centerprint (activator, "Only 1 more to go...");
		}
		return;
	}

	if (activator.classname == "player" && (self.spawnflags & SPAWNFLAG_NOMESSAGE) == 0)
		centerprint(activator, "Sequence completed!");

	self.enemy = activator;
	Trigger_ActivateMultiTrigger(activator);
}

void Trigger_CounterUseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	self.count = self.count - 1;
	if (self.count < 0) return;

	if (self.count != 0)
	{
		if (pActivator.classname == "player" && (self.spawnflags & SPAWNFLAG_NOMESSAGE) == 0)
		{
			if (self.count >= 4)
				centerprint (pActivator, "There are more to go...");
			else if (self.count == 3)
				centerprint (pActivator, "Only 3 more to go...");
			else if (self.count == 2)
				centerprint (pActivator, "Only 2 more to go...");
			else
				centerprint (pActivator, "Only 1 more to go...");
		}
		return;
	}

	if (pActivator.classname == "player" && (self.spawnflags & SPAWNFLAG_NOMESSAGE) == 0)
		centerprint(pActivator, "Sequence completed!");

	self.enemy = pActivator;
	Trigger_ActivateMultiTrigger(pActivator);
}

void trigger_counter()
{
	self.wait = -1;
	if (!self.count) self.count = 2;
	self.use = Trigger_CounterUse;
	self.usehl = Trigger_CounterUseHL;
};