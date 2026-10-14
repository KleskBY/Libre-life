

string SP_PickRespawnLoad()
{
	string slot      = cvar_string("g_lastSaveSlot");
	string savedMap  = cvar_string("g_lastSaveMap");

	if (slot == "")           return "";       // nothing tracked this session
	if (savedMap == mapname)  return slot;     // save is on this level

	// Tracked save is on another level.
	if (Map_IsId1BSP())       return "";       // Quake 1: restart this level
	return slot;	// reload last save
}

.float player_diedAt;              // Player_Die; a bot respawns off it
#define PLAYER_BOT_RESPAWN_DELAY 2 // seconds, past the longest death animation

// The body queue plays the frame it was handed, so a copy taken before the
// death animation stands upright, and one taken in a walking movetype slides.
void Player_CopyCorpse(entity p)
{
	entity corpse = bodyque_head;
	CopyToBodyQue(p);
	corpse.movetype = MOVETYPE_TOSS;
	corpse.velocity = [0, 0, (p.velocity_z < 0) ? p.velocity_z : 0];
}

void Player_BodyQueue(entity p)
{
	if (p.deadflag == DEAD_NO) return;      // nothing died, leave no body
	if (p.modelindex == 0) return;          // DeathThink already handed it over
	if (p.effects & EF_NODRAW) return;      // gibbed: nothing is left to lie there

	if (Player_UseSplitBody() && p.model == PLAYER_MODEL_LEGS)
	{
		setmodel(p, PLAYER_MODEL_FULL);
		Player_TorsoHide(p);
	}

	if (p.frame != p.anim_death_seq) Player_AnimPickDeath(p);
	Player_CopyCorpse(p);
}

void Player_Respawn()
{
	Player_BodyQueue(self);
	if(cvar("gamemode") != MODE_SP)	// coop, deathmatch, team deathmatch
	{
		// Coop respawns at an info_player_coop
		// you into an observer with no route back whenever a team-mate lived.
		SetNewParms();
		PutClientInServer();
	}
	else
	{
		string slot = SP_PickRespawnLoad();
		if (slot != "")
		{
			cvar_set("g_pendingLoad", slot);
			localcmd(strcat("load ", slot, "\n"));
		}
		else
		{
			cvar_set("g_deathRestart", "1");
			localcmd("restart\n");
		}
	}
};

void Player_DeathSound()
{
	// Was switch(Math_RandomInt(1,5)) with only cases 1-3, so two rolls in five
	// DeathSound picks uniformly from these three
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100, "player/pl_pain5.wav", "player/pl_pain6.wav",
	                               "player/pl_pain7.wav");
}

void Player_DeathThink()
{
	self.weaponmodel = "";
	if(self.viewzoom != 0) self.viewzoom = Math_Lerp(self.viewzoom, 1, 0.05);	
	self.punchangle = '0 0 0';

	if (self.flags & FL_ONGROUND)
	{
		float forward = vlen(self.velocity);
		forward = forward - 20;
		if (forward <= 0) self.velocity = '0 0 0';
		else self.velocity = forward * normalize(self.velocity);
	}
	
	if (self.deadflag == DEAD_DYING)
	{
		// Runs once, on the DYING -> DEAD transition.
		if (IsMultiplayer()) PackDeadPlayerItems(self);

		if (self.frame > 100 && IsMultiplayer() && self.movetype == MOVETYPE_NONE)
		{
			Player_CopyCorpse(self);
			self.modelindex = 0;
		}

		self.deadflag = DEAD_DEAD;
	}
	
	// After death animation and on the ground, set movetype to MOVETYPE_NONE to prevent collisions
	if (self.movetype != MOVETYPE_NONE && FBitSet(flags, FL_ONGROUND))
		self.movetype = MOVETYPE_NONE;
		
	//	Monster_StopAnimation();

	if (self.deadflag == DEAD_DEAD)
	{
		if (self.button2 || self.button1 || self.button0) return;
		self.deadflag = DEAD_RESPAWNABLE;
		return;
	}
	
		
		// StartDeathCam(); // go to dead camera. 
	
	if (self.classname == "observer")
		return;	
	
	
	// A bot presses no button, so it waits out the death animation instead;
	// respawning at once queued a body still in the air, in its first frame.
	if (clienttype(self) == CLIENTTYPE_BOT)
	{
		if (time > self.player_diedAt + PLAYER_BOT_RESPAWN_DELAY) Player_Respawn();
		return;
	}
	
	if (!self.button2 && !self.button1 && !self.button0) return;// wait for any button down

	self.button0 = 0;
	self.button1 = 0;
	self.button2 = 0;
	Player_Respawn();

}

void Player_Dead()
{
	self.deadflag = DEAD_DEAD;
}

void Player_Die()
{
	self.player_diedAt = time;
	Sound_CancelDelayed(self);
	self.reload = FALSE;

	self.items = self.items - (self.items & IT_INVISIBILITY);

	// Read BEFORE the model swap below: setmodel replaces .mins/.maxs with the
	// model's own bounds, which reach far below the hull on a model whose
	// animations dip.
	vector cmins = self.mins;

	if (Player_UseSplitBody() && self.model == PLAYER_MODEL_LEGS)
	{
		setmodel(self, PLAYER_MODEL_FULL);
		Player_TorsoHide(self);
	}

	self.weaponmodel = "";
	self.view_ofs = '0 0 -8';
	// Keep the mins the player legally occupied a frame ago and only bring
	// maxs down, the invariant every monster corpse already holds. The old
	// fixed -36 came from a hull this project no longer uses: against the live
	// -24 it put the box 12 units under the floor, MOVETYPE_TOSS had nothing to
	// collide with from inside a brush, and the body fell out of the level. It
	// only happened sometimes because a big enough upward kick popped the box
	// back out first.
	setsize(self, [-12, -12, cmins_z], [12, 12, cmins_z + 8]);

	Player_AnimPickDeath(self);

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
	
	self.nextthink = time + 0.5;
	self.think = Player_Dead;
};
