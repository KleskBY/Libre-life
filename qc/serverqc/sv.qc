void SV_ChangeTeam(float pcolor)
{
	if(cvar("gamemode") == MODE_DM || cvar("gamemode") == MODE_TDM) T_Damage(self, world, world, self.health);
}

void SV_ParseClientCommand(string s)
{
	float argc = tokenize(s);
	string cmd = argv(0); // /say
	string arg1 = argv(1);
	string arg2 = argv(2);
	string arg3 = argv(3); 
	string arg4 = argv(4); 
	if(s == "flashlight")
	{
		Flashlight_Toggle();
		return;
	}
	if(cmd == "p")
	{
		setorigin(self, [stof(arg1), stof(arg2), stof(arg3)]);
		return;
	}
	// if(strlen(s) && strstrofs(s, "/", 0) >= 0)
	// {
		// if(arg1 == "/map")
		// {
			// if(serverAdmin == self)
			// {
				// changelevel(arg2);
			// }
			// return;
		// }
		// else if(arg1 == "/kick")
		// {
			// if(serverAdmin == self)
			// {
				// entity playerToKick = find(world, netname, arg2);
				// if(playerToKick) dropclient(playerToKick);
				// else sprint(self, "Player not found!\n");
			// }
			// return;
		// }
		// else if(arg1 == "/start")
		// {
			// if(serverAdmin == self)
			// {
				// cvar_set ("gamemode", arg2);
				// cvar_set ("skill", arg3);
				// if(cvar("gamemode") == MODE_DM) cvar_set ("teamplay", "0");
				// if(cvar("gamemode") == MODE_COOP) cvar_set ("teamplay", "1");
				// changelevel(arg4);
			// }
			// return;
		// }
	// }
	clientcommand(self, s);
};
