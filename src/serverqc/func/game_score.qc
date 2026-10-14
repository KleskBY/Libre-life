//   master      master gate (string targetname of a multisource / game_team_master)
#define SF_SCORE_NEGATIVE       0x0001
#define SF_SCORE_TEAM           0x0002

.float points;

float GameScore_AllowNegative() { return self.spawnflags & SF_SCORE_NEGATIVE; }
float GameScore_AwardToTeam()   { return self.spawnflags & SF_SCORE_TEAM; }

void GameScore_Award(entity pPlayer, float amt, float allowNeg)
{
	pPlayer.frags += amt;
	if (!allowNeg && pPlayer.frags < 0)
		pPlayer.frags = 0;
}

void GameScore_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	if (!Master_IsTriggered(self.master, pActivator)) return;
	if (!pActivator || pActivator.classname != "player") return;

	float amt = self.points;
	float allowNeg = GameScore_AllowNegative();

	if (GameScore_AwardToTeam())
	{
		// Iterate every player whose .team matches the activator's team.
		entity p = find(world, classname, "player");
		while (p)
		{
			if (p.team == pActivator.team)
				GameScore_Award(p, amt, allowNeg);
			p = find(p, classname, "player");
		}
	}
	else
	{
		GameScore_Award(pActivator, amt, allowNeg);
	}
}

void GameScore_Use()
{
	GameScore_UseHL(activator, self, useType, 0);
}

void game_score()
{
	self.solid    = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.effects  = EF_NODRAW;
	self.use   = GameScore_Use;
	self.usehl = GameScore_UseHL;
}
