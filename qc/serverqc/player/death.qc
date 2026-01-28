

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

void Player_DeathSound()
{
	switch (RandomInt(1,5)) 
	{
		case 1: 
			sound(self, CHAN_VOICE, "player/pl_pain5.wav", 1, ATTN_NORM);
			break;
		case 2: 
			sound(self, CHAN_VOICE, "player/pl_pain6.wav", 1, ATTN_NORM);
			break;
		case 3: 
			sound(self, CHAN_VOICE, "player/pl_pain7.wav", 1, ATTN_NORM);
			break;
	}
}

void Player_DeathThink()
{
	self.weaponmodel = "";
	self.viewzoom = Lerp(self.viewzoom, 1, 0.05);	
	self.punchangle = '0 0 0';
	
	if (self.flags & FL_ONGROUND)
	{
		float forward = vlen(self.velocity);
		forward = forward - 20;
		if (forward <= 0) self.velocity = '0 0 0';
		else self.velocity = forward * normalize(self.velocity);
	}
	
	// if (HasWeapons()) PackDeadPlayerItems();
	if (self.deadflag == DEAD_DYING)
	{
		//Once we finish animating, if we're in multiplayer just make a copy of our body right away.
		if (self.frame > 100 && IsMultiplayer() && self.movetype == MOVETYPE_NONE)
		{
			CopyToBodyQue(self);
			self.modelindex = 0;
		}

		self.deadflag = DEAD_DEAD;
	}
	
	// once we're done animating our death and we're on the ground, we want to set movetype to None so our dead body won't do collisions and stuff anymore
	// this prevents a bug where the dead body would go to a player's head if he walked over it while the dead player was clicking their button to respawn
	if (self.movetype != MOVETYPE_NONE && FBitSet(flags, FL_ONGROUND))
		self.movetype = MOVETYPE_NONE;
		
	//	StopAnimation();

	if (self.deadflag == DEAD_DEAD)
	{
		if (self.button2 || self.button1 || self.button0) return; // wait for all buttons released
		self.deadflag = DEAD_RESPAWNABLE;
		return;
	}
	
	// if the player has been dead for one second longer than allowed by forcerespawn, 
	// forcerespawn isn't on. Send the player off to an intermission camera until they 
	// choose to respawn.
	// if (IsMultiplayer() && (time > (m_fDeadTime + 6 ) &&  !(m_afPhysicsFlags & PFLAG_OBSERVER) )
	// {
		
		// StartDeathCam(); // go to dead camera. 
	// }
	
	if (self.classname == "observer")	// player is in spectator mode
		return;	
	
	
	if (clienttype(self) == CLIENTTYPE_BOT) Player_Respawn();
	
	if (!self.button2 && !self.button1 && !self.button0) return;// wait for any button down

	self.button0 = 0;
	self.button1 = 0;
	self.button2 = 0;
	Player_Respawn();

}

void Player_Die()
{
	self.items = self.items - (self.items & IT_INVISIBILITY);
	self.invisible_finished = 0;
	self.invincible_finished = 0;
	self.super_damage_finished = 0;
	self.radsuit_finished = 0;
	
	self.weaponmodel = "";
	self.view_ofs = '0 0 -8';
	setsize(self, '-12 -12 -36', '12 12 -28');
	
	self.deadflag = DEAD_DYING;
	self.solid = SOLID_CORPSE;
	self.movetype = MOVETYPE_TOSS;
	self.flags = self.flags - (self.flags & FL_ONGROUND);
	if (self.velocity_z < 10) self.velocity_z = self.velocity_z + random() * 300;
	
	if (self.health < -40)
	{
		Gib();
		return;
	}

	Player_DeathSound();
	
	self.angles_x = 0;
	self.angles_z = 0;
};
