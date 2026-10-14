// Keys:
//   teamindex     starting team index (-1 = unset)
//   triggerstate  0=USE_OFF, 2=USE_TOGGLE, default=USE_ON
//   master        master gate
#define SF_TEAMMASTER_FIREONCE     0x0001
#define SF_TEAMMASTER_ANYTEAM      0x0002

.float teamindex;
.float triggerstate;
.float gtm_triggerType;     // resolved from triggerstate at spawn

float GameTeamMaster_RemoveOnFire() { return self.spawnflags & SF_TEAMMASTER_FIREONCE; }
float GameTeamMaster_AnyTeam()      { return self.spawnflags & SF_TEAMMASTER_ANYTEAM; }

// Returns the team ID this master gates on, or -1 if no team is set.
float GameTeamMaster_TeamID(entity ms)
{
	if (ms.teamindex < 0) return -1;
	return ms.teamindex;
}

float GameTeamMaster_TeamMatch(entity ms, entity pActivator)
{
	if (ms.teamindex < 0 && (ms.spawnflags & SF_TEAMMASTER_ANYTEAM))
		return TRUE;
	if (!pActivator) return FALSE;
	return pActivator.team == ms.teamindex;
}

float GameTeamMaster_IsTriggered(entity ms, entity pActivator)
{
	return GameTeamMaster_TeamMatch(ms, pActivator);
}

void GameTeamMaster_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	if (!Master_IsTriggered(self.master, pActivator)) return;

	if (useTypeArg == USE_SET)
	{
		// game_team_set forwards USE_SET: -1 (clear), 0 (learn activator's team), or explicit index.
		if (useValueArg < 0)
		{
			self.teamindex = -1;
		}
		else if (useValueArg == 0)
		{
			if (pActivator)
				self.teamindex = pActivator.team;
		}
		else
		{
			self.teamindex = useValueArg;
		}
		return;
	}

	if (GameTeamMaster_TeamMatch(self, pActivator))
	{
		SUB_UseTargetsHL(pActivator, self.gtm_triggerType, useValueArg);
		if (GameTeamMaster_RemoveOnFire())
			remove(self);
	}
}

void GameTeamMaster_Use()
{
	GameTeamMaster_UseHL(activator, self, useType, 0);
}

void game_team_master()
{
	self.solid    = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.effects  = EF_NODRAW;
	self.object_caps = self.object_caps | FCAP_MASTER;

	switch ((float)self.triggerstate)
	{
	case 0: self.gtm_triggerType = USE_OFF;    break;
	case 2: self.gtm_triggerType = USE_TOGGLE; break;
	default: self.gtm_triggerType = USE_ON;    break;
	}

	// Unset teamindex becomes -1; SF_TEAMMASTER_ANYTEAM pairs with this to allow any trigger.
	if (self.teamindex == 0) self.teamindex = -1;

	self.use   = GameTeamMaster_Use;
	self.usehl = GameTeamMaster_UseHL;
}
