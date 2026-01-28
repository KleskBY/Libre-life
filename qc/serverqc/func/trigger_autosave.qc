



void Trigger_SaveTouch()
{
	if (!UTIL_IsMasterTriggered(self.master, other))
		return;
 	
	if (other.classname != "player")
	{
		return;
	}
	
	stuffcmd(other, "autosave\n");
	self.touch = SUB_Null;
	remove(self);
}


void trigger_autosave()
{
	if(deathmatch || cvar("gamemode") != MODE_SP)
	{
		remove(self);
		return;
	}
	
	InitTrigger();
	self.touch = Trigger_SaveTouch;
};