

// called by ClientKill and DeadThink
void Player_Respawn()
{
	entity e;
	float players;
	
	CopyToBodyQue(self);	// make a copy of the dead body for appearances sake
	if (cvar("gamemode") == MODE_COOP)
	{
		for (e = findchain(classname, "player"); e; e = e.chain) if(IsAlive(e)) players = players + 1;
		if(players) PutObserverInServer();
		else localcmd ("restart\n");
	}
	else if(cvar("gamemode") != MODE_SP) //other deathmatch modes
	{
		SetNewParms();
		PutClientInServer();
	}
	else localcmd("restart\n"); // restart the entire server
};