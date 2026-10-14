// Keys: target (game_team_master targetname), master.
#define SF_PTEAM_FIREONCE          0x0001
#define SF_PTEAM_KILL              0x0002
#define SF_PTEAM_GIB               0x0004

float GameTeamMaster_TeamID(entity ms);

float GamePlayerTeam_RemoveOnFire() { return self.spawnflags & SF_PTEAM_FIREONCE; }
float GamePlayerTeam_KillPlayer()   { return self.spawnflags & SF_PTEAM_KILL; }
float GamePlayerTeam_GibPlayer()    { return self.spawnflags & SF_PTEAM_GIB; }

// Returns a string, collapsed to numeric team id. -1 = "not found / unset".
float GamePlayerTeam_TargetTeamID(string targetName)
{
	entity t = find(world, targetname, targetName);
	while (t)
	{
		if (t.classname == "game_team_master")
			return GameTeamMaster_TeamID(t);
		t = find(t, targetname, targetName);
	}
	return -1;
}

void GamePlayerTeam_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	if (!Master_IsTriggered(self.master, pActivator)) return;

	if (pActivator && pActivator.classname == "player")
	{
		float targetTeam = GamePlayerTeam_TargetTeamID(self.target);
		if (targetTeam >= 0)
		{
			if (GamePlayerTeam_GibPlayer())
				pActivator.health = -99;       // signal gib to Combat_Killed path

			if (GamePlayerTeam_KillPlayer() || GamePlayerTeam_GibPlayer())
				Combat_TakeDamage(pActivator, self, self, 99999, DMG_GENERIC);

			pActivator.team = targetTeam;
		}
	}

	if (GamePlayerTeam_RemoveOnFire())
		remove(self);
}

void GamePlayerTeam_Use()
{
	GamePlayerTeam_UseHL(activator, self, useType, 0);
}

void game_player_team()
{
	self.solid    = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.effects  = EF_NODRAW;
	self.use   = GamePlayerTeam_Use;
	self.usehl = GamePlayerTeam_UseHL;
}
