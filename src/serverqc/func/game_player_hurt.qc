//   master   master gate
#define SF_PKILL_FIREONCE          0x0001

float GamePlayerHurt_RemoveOnFire() { return self.spawnflags & SF_PKILL_FIREONCE; }

void GamePlayerHurt_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	if (!Master_IsTriggered(self.master, pActivator)) return;

	if (pActivator && pActivator.classname == "player")
	{
		if (self.dmg < 0)
			Combat_Heal(pActivator, -self.dmg, FALSE);
		else
			Combat_TakeDamage(pActivator, self, self, self.dmg, DMG_GENERIC);
	}

	SUB_UseTargetsHL(pActivator, useTypeArg, useValueArg);

	if (GamePlayerHurt_RemoveOnFire())
		remove(self);
}

void GamePlayerHurt_Use()
{
	GamePlayerHurt_UseHL(activator, self, useType, 0);
}

void game_player_hurt()
{
	self.solid    = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.effects  = EF_NODRAW;
	self.use   = GamePlayerHurt_Use;
	self.usehl = GamePlayerHurt_UseHL;
}
