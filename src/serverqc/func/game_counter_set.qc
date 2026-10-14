// Keys: frags (the value to set), master, plus target/delay standard.
#define SF_GAMECOUNTSET_FIREONCE   0x0001

float GameCounterSet_RemoveOnFire() { return self.spawnflags & SF_GAMECOUNTSET_FIREONCE; }

void GameCounterSet_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	if (!Master_IsTriggered(self.master, pActivator)) return;

	SUB_UseTargetsHL(pActivator, USE_SET, self.frags);

	if (GameCounterSet_RemoveOnFire())
		remove(self);
}

void GameCounterSet_Use()
{
	GameCounterSet_UseHL(activator, self, useType, 0);
}

void game_counter_set()
{
	self.solid    = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.effects  = EF_NODRAW;
	self.use   = GameCounterSet_Use;
	self.usehl = GameCounterSet_UseHL;
}
