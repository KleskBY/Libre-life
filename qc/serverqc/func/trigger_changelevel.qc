
void changelevel_touch()
{
	if (other.classname != "player") return;
	if (other.viewmodel) setmodel(other.viewmodel, "");
	if (cvar("noexit") == 1 || cvar("noexit") == 2 && mapname != "start")
	{
		T_Damage (other, self, self, 50000);
		return;
	}
	
	if (cvar("gamemode") != MODE_SP)
	{
		bprint(other.netname);
		bprint(" exited the level\n");
	}

	SUB_UseTargets();
	changelevel(self.map);
};


void trigger_changelevel()
{
	if (!self.map) objerror("chagnelevel trigger doesn't have map");
	InitTrigger();
	self.touch = changelevel_touch;
};