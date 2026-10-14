
void Q1Intermission_Begin(entity pActivator, string mapTo);

void GameEnd_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	if (!Master_IsTriggered(self.master, pActivator)) return;

	if (IsMultiplayer())
	{
		// uses last set trigger map, or current map (engine clamps)
		Q1Intermission_Begin(pActivator, nextmap != "" ? nextmap : mapname);
	}
	else
	{
		dprint("game_end fired in SP (no-op)\n");
	}
}

void GameEnd_Use()
{
	GameEnd_UseHL(activator, self, useType, 0);
}

void game_end()
{
	self.solid    = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.effects  = EF_NODRAW;
	self.use   = GameEnd_Use;
	self.usehl = GameEnd_UseHL;
}
