
void Steam_AchievementUnlock(string ach_name)
{
	if(!cvar("steam_steamid")) return;
	if(!cvar("pr_checkextension")) return;
	if (checkextension("KLESKBY_STEAM"))
	{
		string cvar_name = strtolower(ach_name);
		if(cvar(cvar_name)) return;
		if(steam_achievement_unlock(ach_name))
		{
			string str = "seta ";
			str = strcat(str, cvar_name);
			str = strcat(str, " 1\n");
			localcmd(str);
		}
	}
}

float achievements_once;
void Steam_PorcessAchievements()
{
	if(!intermission) return;
	if(!cvar("steam_steamid")) return;
	if(!cvar("pr_checkextension")) return;
	if(!checkextension("KLESKBY_STEAM")) return;
	if(achievements_once) return;
	achievements_once = true;
	if(mapname == "maps/e1m8.bsp")
	{
		Steam_AchievementUnlock("ACH_FINISH_EPISODE_ONE");
	}
	if(mapname == "maps/e1m1.bsp")
	{
		Steam_AchievementUnlock("ACH_FINISH_E1M1");
	}
	if(mapname == "maps/e1m2.bsp")
	{
		if(getstati(STAT_SECRETS) == getstati(STAT_TOTALSECRETS))
			Steam_AchievementUnlock("ACH_ALL_SECRETS_E1M2");
	}
	if(playerHealth <= 10) 
		Steam_AchievementUnlock("ACH_LOW_HEALTH_FINISH");
	
	float accuracy = floor(getstati(STAT_HITS) / getstati(STAT_SHOTS) * 100);
	if(accuracy >= 95 && getstati(STAT_SHOTS) >= 5) 
		Steam_AchievementUnlock("ACH_ACCURACY");
		
	if(time < 60)
		if(mapname != "maps/start.bsp")
			Steam_AchievementUnlock("ACH_SPEEDRUNNER");
};

void Steam_AchievementReset()
{
	steam_achievement_lock("ACH_SPEEDRUNNER");
	steam_achievement_lock("ACH_LOW_HEALTH_FINISH");
	steam_achievement_lock("ACH_ALL_SECRETS_E1M2");
	steam_achievement_lock("ACH_FINISH_E1M1");
	steam_achievement_lock("ACH_FINISH_EPISODE_ONE");
	steam_achievement_lock("ACH_PAGE");
	steam_achievement_lock("ACH_BEER");
};