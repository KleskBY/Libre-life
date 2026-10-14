//   master   master gate
#define SF_TEAMSET_FIREONCE        0x0001
#define SF_TEAMSET_CLEARTEAM       0x0002

float GameTeamSet_RemoveOnFire()  { return self.spawnflags & SF_TEAMSET_FIREONCE; }
float GameTeamSet_ShouldClear()   { return self.spawnflags & SF_TEAMSET_CLEARTEAM; }

void GameTeamSet_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	if (!Master_IsTriggered(self.master, pActivator)) return;

	float val = GameTeamSet_ShouldClear() ? -1 : 0;
	SUB_UseTargetsHL(pActivator, USE_SET, val);

	if (GameTeamSet_RemoveOnFire())
		remove(self);
}

void GameTeamSet_Use()
{
	GameTeamSet_UseHL(activator, self, useType, 0);
}

void game_team_set()
{
	self.solid    = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.effects  = EF_NODRAW;
	self.use   = GameTeamSet_Use;
	self.usehl = GameTeamSet_UseHL;
}
