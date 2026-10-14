// Keys: frags, health, master, plus target/delay/killtarget standard.
#define SF_GAMECOUNT_FIREONCE      0x0001
#define SF_GAMECOUNT_RESET         0x0002

float GameCounter_RemoveOnFire() { return self.spawnflags & SF_GAMECOUNT_FIREONCE; }
float GameCounter_ResetOnFire()  { return self.spawnflags & SF_GAMECOUNT_RESET; }

void GameCounter_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	if (!Master_IsTriggered(self.master, pActivator)) return;

	switch (useTypeArg)
	{
	case USE_ON:
	case USE_TOGGLE:
		self.frags = self.frags + 1;
		break;
	case USE_OFF:
		self.frags = self.frags - 1;
		break;
	case USE_SET:
		self.frags = useValueArg;
		break;
	}

	if (self.frags == self.health)
	{
		SUB_UseTargetsHL(pActivator, USE_TOGGLE, 0);
		if (GameCounter_RemoveOnFire())
		{
			remove(self);
			return;
		}
		if (GameCounter_ResetOnFire())
			self.frags = self.dmg;
	}
}

void GameCounter_Use()
{
	GameCounter_UseHL(activator, self, useType, 0);
}

void game_counter()
{
	self.solid    = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.effects  = EF_NODRAW;

	// Stash initial count so SF_GAMECOUNT_RESET can restore it.
	self.dmg = self.frags;

	self.use   = GameCounter_Use;
	self.usehl = GameCounter_UseHL;
}
