
.float crouching;
.float running;
.float stamina;

float PLAYER_STAMINA_DECREASE = 9;
float PLAYER_STAMINA_REGEN = 6;

float STANCE_TRACE_EPS = 1;

float PlayerStance_HullFits(vector org, vector hullMin, vector hullMax)
{
	tracebox(org, hullMin, hullMax, org + [0, 0, STANCE_TRACE_EPS], FALSE, self);
	if (trace_startsolid || trace_allsolid || trace_fraction < 1)
		return FALSE;
	return TRUE;
}

// Returns TRUE if the standing hull fits at standOrigin.
float PlayerStance_CanStandAt(vector standOrigin)
{
	traceline(standOrigin, standOrigin + [0, 0, PLAYER_STAND_SIZE_MAX_z], FALSE, self);
	if (trace_startsolid || trace_fraction < 1)
		return FALSE;

	return PlayerStance_HullFits(standOrigin, PLAYER_STAND_SIZE_MIN, PLAYER_STAND_SIZE_MAX);
}

#if HL1_CROUCHJUMP

void PlayerStanceCrouch()
{
	self.crouching = 1;
	self.running = 0;
	self.duckStartTime = time;	// longjump gate: ~1s window

	if (!(self.flags & FL_ONGROUND))
	{
		if (PlayerStance_HullFits(self.origin, PLAYER_DUCK_AIR_SIZE_MIN, PLAYER_DUCK_AIR_SIZE_MAX))
		{
			setsize(self, PLAYER_DUCK_AIR_SIZE_MIN, PLAYER_DUCK_AIR_SIZE_MAX);
			self.duckedInAir = 1;
			self.view_ofs = DUCK_VIEW_OFS;
			return;
		}
	}

	// Ground duck (or air fallback if air-duck blocked).
	self.duckedInAir = 0;
	setsize(self, PLAYER_DUCK_SIZE_MIN, PLAYER_DUCK_SIZE_MAX);
	self.view_ofs = DUCK_VIEW_OFS;
};

void PlayerStanceWalk()
{
	self.crouching = 0;
	self.duckedInAir = 0;
	setsize(self, PLAYER_STAND_SIZE_MIN, PLAYER_STAND_SIZE_MAX);
	self.view_ofs = STAND_VIEW_OFS;
};

// the box bottom 18u, used for the crouch-jump effect
void PlayerStance_PromoteAirDuck()
{
	if (PlayerStance_HullFits(self.origin, PLAYER_DUCK_AIR_SIZE_MIN, PLAYER_DUCK_AIR_SIZE_MAX))
	{
		setsize(self, PLAYER_DUCK_AIR_SIZE_MIN, PLAYER_DUCK_AIR_SIZE_MAX);
		self.duckedInAir = 1;
	}
}

// Origin rises 18u so the wider mins (-24) places feet on the surface.
void PlayerStance_DemoteGroundDuck()
{
	vector newOrigin = self.origin + [0, 0, DUCK_AIR_HULL_OFS];
	if (PlayerStance_HullFits(newOrigin, PLAYER_DUCK_SIZE_MIN, PLAYER_DUCK_SIZE_MAX))
	{
		setorigin(self, newOrigin);
		setsize(self, PLAYER_DUCK_SIZE_MIN, PLAYER_DUCK_SIZE_MAX);
		self.duckedInAir = 0;
	}
	// else: keep air-duck hull on ground. Uncrouch logic handles via standOrigin += 18.
}

void PlayerStance_TryStand(vector standOrigin)
{
	vector oldOrigin;
	vector oldMin;
	vector oldMax;
	float  oldDuckedInAir;

	if (!PlayerStance_CanStandAt(standOrigin))
		return;

	oldOrigin      = self.origin;
	oldMin         = self.mins;
	oldMax         = self.maxs;
	oldDuckedInAir = self.duckedInAir;

	if (self.duckedInAir)
		setorigin(self, standOrigin);
	PlayerStanceWalk();

	if (!PlayerStance_HullFits(self.origin, self.mins, self.maxs))
	{
		setorigin(self, oldOrigin);
		setsize(self, oldMin, oldMax);
		self.crouching    = 1;
		self.duckedInAir  = oldDuckedInAir;
		self.view_ofs     = DUCK_VIEW_OFS;
	}
}

void Player_Stance()
{
	//Crouch
	if(self.button3)	// holding crouch button
	{
		if(!self.crouching)
		{
			PlayerStanceCrouch();
		}
		else
		{
			if (!(self.flags & FL_ONGROUND) && !self.duckedInAir && self.velocity_z > 0)
				PlayerStance_PromoteAirDuck();
			else if ((self.flags & FL_ONGROUND) && self.duckedInAir)
				PlayerStance_DemoteGroundDuck();
		}
	}
	else if(self.crouching)
	{
		vector standOrigin;
		if (self.duckedInAir)
			standOrigin = self.origin + [0, 0, DUCK_AIR_HULL_OFS];
		else
			standOrigin = self.origin;

		PlayerStance_TryStand(standOrigin);
	}

	//Sprint
	if(self.button4 && !self.button0)
	{
		if(!self.crouching && !self.running /*&& self.stamina > 30*/)
		{
			self.running = TRUE;
		}
	}
	else if(!self.crouching && self.running)
	{
		self.running = FALSE;
	}
}

#else

void PlayerStanceCrouch()
{
	self.crouching = 1;
	self.running = 0;
	self.duckStartTime = time;	// longjump gate: ~1s window
	setsize(self, PLAYER_DUCK_SIZE_MIN, PLAYER_DUCK_SIZE_MAX);
	self.view_ofs = DUCK_VIEW_OFS;
};

void PlayerStanceWalk()
{
	self.crouching = 0;
	setsize(self, PLAYER_STAND_SIZE_MIN, PLAYER_STAND_SIZE_MAX);
	self.view_ofs = STAND_VIEW_OFS;
};

void Player_Stance()
{
	//Crouch
	if(self.button3)	// holding crouch button
	{
		if(!self.crouching)
		{
			PlayerStanceCrouch();
		}
	}
	else if(self.crouching)
	{
		if (PlayerStance_CanStandAt(self.origin))
		{
			vector oldMin = self.mins;
			vector oldMax = self.maxs;

			PlayerStanceWalk();

			if (!PlayerStance_HullFits(self.origin, self.mins, self.maxs))
			{
				setsize(self, oldMin, oldMax);
				self.crouching = 1;
				self.view_ofs = DUCK_VIEW_OFS;
			}
		}
	}

	//Sprint
	if(self.button4 && !self.button0)
	{
		if(!self.crouching && !self.running /*&& self.stamina > 30*/)
		{
			self.running = TRUE;
		}
	}
	else if(!self.crouching && self.running)
	{
		self.running = FALSE;
	}
}

#endif  // HL1_CROUCHJUMP
